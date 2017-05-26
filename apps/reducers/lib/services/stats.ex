defmodule Service.Stats do
  @behaviour Reducer

  alias DB.Event
  alias Reducer.State

  import DB.Validation, only: [flip_v1_uuid: 1]

  @types [:bin_audit, :actuals, :pre_actual, :refill_actual, :pre_challenge, :refill_challenge]
  def types do
    @types
  end

  @spec call(list(Event.t), State.t) :: State.t
  def call(events, %State{} = state) when is_list(events) do
    {new_model, new_events} = events
    |> validate()
    |> stats_reducer_recursive({state.model, []})
    %State{state | model: new_model, new_events: new_events}
  end

  def correct_type?(event) do
    Enum.member?([
      "actuals",
      "bin_audit",
      "pre_actual",
      "refill_actual",
      "pre_challenge",
      "refill_challenge"], event.type)
  end

  def validate(event_list) do
    Enum.filter(event_list, fn(event) -> correct_type?(event) end)
    |> Enum.map( fn(event) -> event_structure(event) end)
    |> sorts_events()
  end

  def uuidv1({_type, event}) do
    event.ordered_id
  end

  def sorts_events(event_list)do
    Enum.sort(event_list, &(uuidv1(&1) < uuidv1(&2)))
  end

  def event_structure(event) do
    type = String.to_existing_atom(String.downcase(event.type))
    data = %{
        entity_id: event.entity_id,
        event_id: event.event_id,
        domain: event.domain,
        ordered_id: flip_v1_uuid(event.event_id),
        data: event.meta
      }
    {type, data}
  end

  def stats_reducer_recursive([], {model, new_events}), do: {model, new_events}
  def stats_reducer_recursive([event | remaining_events], {model, new_events}) do
    stats_reducer_recursive(remaining_events, play(event, {model, new_events}))
  end

  def get_timestamp({:bin_audit, event}), do: date(event.data["DATE"])
  def get_timestamp({:actuals, event}), do: date(event.data["Metrics"])
  def get_timestamp({:pre_challenge, event})do
    max = Enum.max_by(event.data["users"], fn(user) -> elem(user, 1)["start_time"] end)
    elem(max, 1)["start_time"]
  end

  def get_timestamp({:refill_challenge, event})do
    max = Enum.max_by(event.data["users"], fn(user) -> elem(user, 1)["start_time"] end)
    elem(max, 1)["start_time"]
  end

  def date(datestring) when datestring == "" do
    1494287000000 #this date will be before season1 starts, so it won't get played
  end

  def date(datestring) do
    [month, day, year] = String.split(datestring, "/")
    seconds = Timex.to_datetime({{String.to_integer(year), String.to_integer(month), String.to_integer(day)}, {16, 0, 0}})
    |> Timex.to_unix()
    seconds * 1000
  end

  def find_period(timestamp, season_periods) do
    {period, _data} = Application.get_env(:reducers, season_periods)
    |>  Enum.find({:out_of_season, "data"}, fn {_period, %{:start_time => start_time, :end_time => end_time}} -> timestamp >= start_time and timestamp <= end_time end)
    to_string(period)
  end

  def get_period_model(_period, model) when map_size(model) == 0 do
    model = %{}
    model
  end

  def get_period_model(period, model) when period == "out_of_season" do
    :out_of_season
  end

  def get_period_model(period, model) do
    model["stats"][period] || %{}
  end



  def play({type, event}, {model, new_events}) do
    period = get_timestamp({type, event})
    |> find_period(Application.get_env(:reducers, :current_periods))
    period_model = get_period_model(period, model)

    get_new_model({type, event}, {period_model, new_events}, model, period)
  end

  def get_new_model({type, event}, {:out_of_season, new_events}, model, period) do
    {model, new_events}
  end
  def get_new_model({type, event}, {period_model, new_events}, model, period) do
    {new_period_model, additional_events} = apply(Service.Stats, type, [{type, event}, {period_model, new_events}])
    {model
    |> Map.put("stats", model["stats"] || %{})
    |> put_in(["stats", period], new_period_model)
    |> Map.put("season", Application.get_env(:reducers, :current_season))
    |> Map.put("last_played", event.ordered_id), Enum.into(additional_events, new_events)}
  end


  def add_meta(event, meta)do
    Enum.map(event.data["users"], fn ({k, v}) -> {event.data["challenge_id"] <> "-" <> k, v} end)
    |> Enum.into(meta)
  end

  def count_sum(meta, metric)do
    filtered_scores = Enum.filter(meta, fn({_k, score}) -> score["status"] != "deleted" end)
    {Enum.count(filtered_scores), Enum.reduce(filtered_scores, 0, fn({_k, score}, acc) -> score[metric] + acc end)}
  end

  def average(meta, metric) do
    {count, sum} = count_sum(meta, metric)
    sum / count
  end

  def percentage_score(percent) do
    cond do
      percent >= 1.20 -> 15
      percent >= 1.00 -> 10
      percent >= 0.9 -> 5
      true -> 0
    end
  end

  def bin_audit_score(percent) do
    cond do
      percent >= 100 -> 15
      percent >= 90 -> 10
      percent >= 80 -> 5
      true -> 0
    end
  end

  def accuracy_score(percent) do
    cond do
      percent >= 1.10 -> 0
      percent >= 1.00 -> 20
      percent >= 0.9 -> 10
      percent >= 0.8 -> 8
      percent >= 0.7 -> 6
      percent >= 0.6 -> 4
      percent >= 0.5 -> 2
      true -> 0
    end
  end

  def pre_challenge({_type, event}, {%{"pre" => %{"actual_units" => _actual_units}} = period_model, new_events}) do
    meta = add_meta(event, period_model["pre"]["pre_meta"])
    {_count, sum} = count_sum(meta, "actual_units")
    average = average(meta, "percentage")
    score = percentage_score(average)
    {accuracy_percentage, accuracy_score} = accuracy(sum, period_model["pre"]["actual_units"])

    {period_model
    |> put_in(["pre", "pre_meta"], meta)
    |> put_in(["pre", "pre_score"], score)
    |> put_in(["pre", "pre_percentage"], average)
    |> put_in(["pre", "accuracy_score"], accuracy_score)
    |> put_in(["pre", "accuracy_percentage"], accuracy_percentage)
    |> put_in(["pre", "pre_units"], sum), new_events}
  end

  def pre_challenge({_type, event}, {%{"pre" => _pre} = period_model, new_events}) do
    meta = add_meta(event, period_model["pre"]["pre_meta"])
    {_count, sum} = count_sum(meta, "actual_units")
    average = average(meta, "percentage")
    score = percentage_score(average)

    {period_model
    |> put_in(["pre", "pre_meta"], meta)
    |> put_in(["pre", "pre_score"], score)
    |> put_in(["pre", "pre_percentage"], average)
    |> put_in(["pre", "pre_units"], sum), new_events}
  end

  def pre_challenge({_type, event}, {period_model, new_events}) do
    meta = add_meta(event, %{})
    {_count, sum} = count_sum(meta, "actual_units")
    average = average(meta, "percentage")
    score = percentage_score(average)

    {period_model
    |> Map.put("pre", %{})
    |> put_in(["pre", "pre_meta"], meta)
    |> put_in(["pre", "pre_score"], score)
    |> put_in(["pre", "pre_percentage"], average)
    |> put_in(["pre", "pre_units"], sum), new_events}
  end

  def refill_challenge({_type, event}, {%{"refill" => %{"actual_units" => _actual_units}} = period_model, new_events}) do
    meta = add_meta(event, period_model["refill"]["refill_meta"])
    {_count, sum} = count_sum(meta, "actual_units")
    average = average(meta, "percentage")
    score = percentage_score(average)
    {accuracy_percentage, accuracy_score} = accuracy(sum, period_model["refill"]["actual_units"])

    {period_model
    |> put_in(["refill", "refill_meta"], meta)
    |> put_in(["refill", "refill_score"], score)
    |> put_in(["refill", "refill_percentage"], average)
    |> put_in(["refill", "accuracy_score"], accuracy_score)
    |> put_in(["refill", "accuracy_percentage"], accuracy_percentage)
    |> put_in(["refill", "refill_units"], sum), new_events}
  end

  def refill_challenge({_type, event}, {%{"refill" => _refill} = period_model, new_events}) do
    meta = add_meta(event, period_model["refill"]["refill_meta"])
    {_count, sum} = count_sum(meta, "actual_units")
    average = average(meta, "percentage")
    score = percentage_score(average)

    {period_model
    |> put_in(["refill", "refill_meta"], meta)
    |> put_in(["refill", "refill_score"], score)
    |> put_in(["refill", "refill_percentage"], average)
    |> put_in(["refill", "refill_units"], sum), new_events}
  end

  def refill_challenge({_type, event}, {period_model, new_events}) do
    meta = add_meta(event, %{})
    {_count, sum} = count_sum(meta, "actual_units")
    average = average(meta, "percentage")
    score = percentage_score(average)

    {period_model
    |> Map.put("refill", %{})
    |> put_in(["refill", "refill_meta"], meta)
    |> put_in(["refill", "refill_score"], score)
    |> put_in(["refill", "refill_percentage"], average)
    |> put_in(["refill", "refill_units"], sum), new_events}
  end


  def bin_audit({_type, event}, {period_model, new_events}) do
    {period_model
    |> Map.put("bin_audit", %{})
    |> put_in(["bin_audit", "bin_percentage"], event.data["BIN_PERCENTAGE"])
    |> put_in(["bin_audit", "bin_score"], bin_audit_score(event.data["BIN_PERCENTAGE"])), new_events}
  end

  def actuals({_type, event}, {period_model, new_events}) do
    cond do
      event.data["Metrics2"] == "Actual Receipts" -> pre_actual({:pre_actual, event}, {period_model, new_events})
      event.data["Metrics2"] == "Actual Units Sold" -> refill_actual({:refill_actual, event}, {period_model, new_events})
    end
  end


  def add_actuals(event, meta)do
    meta
    |> Map.put(event.event_id, event.data["Count"])
  end

  def sum_actuals(meta)do
    Enum.reduce(meta, 0, fn({_k, score}, acc) -> score + acc end)
  end

  def accuracy(app_units, actual_units)do
    percentage = app_units / actual_units
    score = accuracy_score(percentage)
    {percentage, score}
  end


  def pre_actual({_type, event}, {%{"pre" => %{"pre_units" => _pre_units}} = period_model, new_events}) do
    meta = add_actuals(event, period_model["pre"]["actuals_meta"] || %{})
    sum =  sum_actuals(meta)
    {percentage, score} = accuracy(period_model["pre"]["pre_units"], sum)

    {period_model
    |> put_in(["pre", "actuals_meta"], meta)
    |> put_in(["pre", "actual_units"], sum)
    |> put_in(["pre", "accuracy_score"], score)
    |> put_in(["pre", "accuracy_percentage"], percentage),
    new_events}
  end

  def pre_actual({_type, event}, {%{"pre" => _pre} = period_model, new_events}) do
    meta = add_actuals(event, period_model["pre"]["actuals_meta"] || %{})
    sum =  sum_actuals(meta)

    {period_model
    |> put_in(["pre", "actuals_meta"], meta)
    |> put_in(["pre", "actual_units"], sum),
    new_events}
  end

  def pre_actual({_type, event}, {period_model, new_events}) do
    meta = add_actuals(event, period_model["pre"]["actuals_meta"] || %{})
    sum =  sum_actuals(meta)

    {period_model
    |> Map.put("pre", %{})
    |> put_in(["pre", "actuals_meta"], meta)
    |> put_in(["pre", "actual_units"], sum),
    new_events}
  end

  def refill_actual({_type, event}, {%{"refill" => %{"refill_units" => _refill_units}} = period_model, new_events}) do
    meta = add_actuals(event, period_model["refill"]["actuals_meta"] || %{})
    sum =  sum_actuals(meta)
    {percentage, score} = accuracy(period_model["refill"]["refill_units"], sum)

    {period_model
    |> put_in(["refill", "actuals_meta"], meta)
    |> put_in(["refill", "actual_units"], sum)
    |> put_in(["refill", "accuracy_score"], score)
    |> put_in(["refill", "accuracy_percentage"], percentage),
    new_events}
  end

  def refill_actual({_type, event}, {%{"refill" => _refill} = period_model, new_events}) do
    meta = add_actuals(event, period_model["refill"]["actuals_meta"] || %{})
    sum =  sum_actuals(meta)
    {percentage, score} = accuracy(period_model["refill"]["refill_units"], sum)

    {period_model
    |> put_in(["refill", "actuals_meta"], meta)
    |> put_in(["refill", "actual_units"], sum)
    |> put_in(["refill", "accuracy_score"], score)
    |> put_in(["refill", "accuracy_percentage"], percentage),
    new_events}
  end

  def refill_actual({_type, event}, {period_model, new_events}) do
    meta = add_actuals(event, period_model["refill"]["actuals_meta"] || %{})
    sum =  sum_actuals(meta)

    {period_model
    |> Map.put("refill", %{})
    |> put_in(["refill", "actuals_meta"], meta)
    |> put_in(["refill", "actual_units"], sum),
    new_events}
  end
end
