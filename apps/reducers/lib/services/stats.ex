require Logger

defmodule Service.Stats do
  @behaviour Reducer

  import DB.Validation, only: [flip_v1_uuid: 1]

  alias DB.Event
  alias Reducer.State

  @domains [:stats]
  @orderable false
  @types [:bin_audit, :actuals, :pre_actual, :refill_actual, :pre_challenge, :refill_challenge]
  def domains, do: @domains
  def types, do: @types
  def orderable, do: @orderable

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
  def get_timestamp({:actuals, event}), do: date(event.data["Week"])
  def get_timestamp({:pre_actual, event}), do: date(event.data["Week"])
  def get_timestamp({:refill_actual, event}), do: date(event.data["Week"])
  def get_timestamp({:pre_challenge, event})do
    max = Enum.max_by(event.data["users"], fn(user) -> elem(user, 1)["start_time"] end)
    elem(max, 1)["start_time"]
  end
  def get_timestamp({:refill_challenge, event})do
    max = Enum.max_by(event.data["users"], fn(user) -> elem(user, 1)["start_time"] end)
    elem(max, 1)["start_time"]
  end

  def date(datestring) when datestring == "", do: 1494287000000 #this date will be before season1 starts, so it won't get played
  def date(datestring) when is_nil(datestring), do: 1494287000000 #this date will be before season1 starts, so it won't get played
  def date(datestring) when datestring == "0", do: 1494287000000 #this date will be before season1 starts, so it won't get played
  def date(datestring) do
    {year, month, day} = case Regex.match?(~r/-/, datestring) do
      true -> [year, month, day] = String.split(datestring, "-")
        {year, month, day}
      false ->[month, day, year] = String.split(datestring, "/")
        {year, month, day}
    end
    seconds = Timex.to_datetime({{String.to_integer(year), String.to_integer(month), String.to_integer(day)}, {16, 0, 0}})
    |> Timex.to_unix()
    seconds * 1000
  end

  def find_period(timestamp, season_periods) do
    {period, _data} = Application.get_env(:reducers, season_periods)
    |>  Enum.find({:out_of_season, "data"}, fn {_period, %{:start_time => start_time, :end_time => end_time}} -> timestamp >= start_time and timestamp <= end_time end)
    to_string(period)
  end

  def get_period_model(period, _model) when period == "out_of_season", do: :out_of_season
  def get_period_model(_period, model) when map_size(model) == 0 do
    model = %{}
    model
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

  def get_new_model({_type, _event}, {:out_of_season, new_events}, model, _period), do: {model, new_events}
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
    filtered_scores = Enum.filter(meta, fn({_k, score}) -> score["status"] == "completed" || score["status"] == "editted" end)
    {Enum.count(filtered_scores), Enum.reduce(filtered_scores, 0,
      fn
        {_k, %{^metric => actual_data}}, acc  when is_number(actual_data) -> actual_data + acc
        {_k, %{^metric => actual_data}}, acc   ->
          {data, _} = Float.parse(actual_data)
          data + acc
      end)}
  end

  def average(meta, metric) do
    {count, sum} = count_sum(meta, metric)
    case count > 0 do
      true -> sum / count
      false -> 0
    end
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

  def pre_challenge({type, event}, {%{"pre" => %{"actual_units" => _actual_units, "pre_meta" => _meta}} = period_model, new_events}) do
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
    |> put_in(["pre", "pre_units"], sum)
    |> calculate_bin_audit({type, event}),
    new_events}
  end

  def pre_challenge({type, event}, {%{"pre" => %{"pre_meta" => _meta}} = period_model, new_events}) do
    meta = add_meta(event, period_model["pre"]["pre_meta"])
    {_count, sum} = count_sum(meta, "actual_units")
    average = average(meta, "percentage")
    score = percentage_score(average)

    {period_model
    |> put_in(["pre", "pre_meta"], meta)
    |> put_in(["pre", "pre_score"], score)
    |> put_in(["pre", "pre_percentage"], average)
    |> put_in(["pre", "pre_units"], sum)
    |> calculate_bin_audit({type, event}),
    new_events}
  end

  def pre_challenge({type, event}, {period_model, new_events}) do
    meta = add_meta(event, %{})
    {_count, sum} = count_sum(meta, "actual_units")
    average = average(meta, "percentage")
    score = percentage_score(average)

    {period_model
    |> Map.put("pre", %{})
    |> put_in(["pre", "pre_meta"], meta)
    |> put_in(["pre", "pre_score"], score)
    |> put_in(["pre", "pre_percentage"], average)
    |> put_in(["pre", "pre_units"], sum)
    |> calculate_bin_audit({type, event}),
    new_events}
  end

  def refill_challenge({type, event}, {%{"refill" => %{"actual_units" => _actual_units, "refill_meta" => _meta}} = period_model, new_events}) do
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
    |> put_in(["refill", "refill_units"], sum)
    |> calculate_bin_audit({type, event}),
    new_events}
  end

  def refill_challenge({type, event}, {%{"refill" => %{"refill_meta" => _meta}} = period_model, new_events}) do
    meta = add_meta(event, period_model["refill"]["refill_meta"])
    {_count, sum} = count_sum(meta, "actual_units")
    average = average(meta, "percentage")
    score = percentage_score(average)

    {period_model
    |> put_in(["refill", "refill_meta"], meta)
    |> put_in(["refill", "refill_score"], score)
    |> put_in(["refill", "refill_percentage"], average)
    |> put_in(["refill", "refill_units"], sum)
    |> calculate_bin_audit({type, event}),
    new_events}
  end

  def refill_challenge({type, event}, {period_model, new_events}) do
    meta = add_meta(event, %{})
    {_count, sum} = count_sum(meta, "actual_units")
    average = average(meta, "percentage")
    score = percentage_score(average)

    {period_model
    |> Map.put("refill", %{})
    |> put_in(["refill", "refill_meta"], meta)
    |> put_in(["refill", "refill_score"], score)
    |> put_in(["refill", "refill_percentage"], average)
    |> put_in(["refill", "refill_units"], sum)
    |> calculate_bin_audit({type, event}),
    new_events}
  end


  def bin_audit({_type, event}, {period_model, new_events}) do
    case Float.parse(event.data["BIN_PERCENTAGE"]) do
     {bin_percentage, _} ->
       {period_model
       |> Map.put("bin_audit", %{})
       |> put_in(["bin_audit", "bin_percentage"], bin_percentage)
       |> put_in(["bin_audit", "bin_score"], bin_audit_score(bin_percentage)), new_events}
     :error ->
       {period_model
       |> Map.put("bin_audit", %{})
       |> put_in(["bin_audit", "bin_percentage"], 0)
       |> put_in(["bin_audit", "bin_score"], bin_audit_score(0)), new_events}
     end
  end

  def actuals({_type, event}, {period_model, new_events}) do
    cond do
      event.data["Metrics"] == "Actual Receipts" -> pre_actual({:pre_actual, event}, {period_model, new_events})
      event.data["Metrics"] == "Actual Units Sold" -> refill_actual({:refill_actual, event}, {period_model, new_events})
    end
  end

  def add_actuals({type, %{data: %{"Count" => count}}} = _event, meta) when count == nil, do: meta
  def add_actuals({type, %{data: %{"Count" => count}}} = event, meta) when is_binary(count) do
     case Float.parse(count) do
      {count, _} ->
        meta
        |> Map.put(to_string(get_timestamp(event)) <> to_string(count), count)
      :error ->
        meta
      end
  end
  def add_actuals({type, %{data: %{"Count" => count}}} = event, meta) when is_number(count) do
        meta
        |> Map.put(to_string(get_timestamp(event)) <> to_string(count), count)
  end

  def sum_actuals(meta)do
    Enum.reduce(meta, 0, fn({_k, score}, acc) -> score + acc end)
  end

  def accuracy(_app_units, actual_units) when actual_units == 0 ,do: {0, 0}
  def accuracy(_app_units, actual_units) when actual_units == "0", do: {0, 0}
  def accuracy(app_units, actual_units) when is_nil(actual_units) or is_nil(app_units), do: {0, 0}
  def accuracy(app_units, actual_units) when is_number(app_units) and is_number(actual_units) do
    percentage = app_units / actual_units
    score = accuracy_score(percentage)
    {percentage, score}
  end

  def accuracy(app_units, actual_units) when is_number(actual_units) do
    {app_units_float, _} = Float.parse(app_units)
    percentage = app_units_float / actual_units
    score = accuracy_score(percentage)
    {percentage, score}
  end

  def accuracy(app_units, _actual_units) when is_number(app_units) do
    {actual_units_float, _} = Float.parse(app_units)
    percentage = app_units / actual_units_float
    score = accuracy_score(percentage)
    {percentage, score}
  end

  def pre_actual({type, event}, {%{"pre" => %{"pre_units" => pre_units}} = period_model, new_events}) do
    meta = add_actuals({type, event}, period_model["pre"]["actuals_meta"] || %{})
    sum =  sum_actuals(meta)
    {percentage, score} = accuracy(pre_units, sum)

    {period_model
    |> put_in(["pre", "actuals_meta"], meta)
    |> put_in(["pre", "actual_units"], sum)
    |> put_in(["pre", "accuracy_score"], score)
    |> put_in(["pre", "accuracy_percentage"], percentage)
    |> calculate_bin_audit({type, event}),
    new_events}
  end

  def pre_actual({type, event}, {%{"pre" => _pre} = period_model, new_events}) do
    meta = add_actuals({type, event}, period_model["pre"]["actuals_meta"] || %{})
    sum =  sum_actuals(meta)

    {period_model
    |> put_in(["pre", "actuals_meta"], meta)
    |> put_in(["pre", "actual_units"], sum)
    |> calculate_bin_audit({type, event}),
    new_events}
  end

  def pre_actual({type, event}, {period_model, new_events}) do
    meta = add_actuals({type, event}, period_model["pre"]["actuals_meta"] || %{})
    sum =  sum_actuals(meta)

    {period_model
    |> Map.put("pre", %{})
    |> put_in(["pre", "actuals_meta"], meta)
    |> put_in(["pre", "actual_units"], sum)
    |> calculate_bin_audit({type, event}),
    new_events}
  end

  def refill_actual({type, event}, {%{"refill" => %{"refill_units" => refill_units}} = period_model, new_events})  when is_nil(refill_units) != true do
    meta = add_actuals({type, event}, period_model["refill"]["actuals_meta"] || %{})
    sum =  sum_refill_actuals(event.data["Store"], meta)
    {percentage, score} = accuracy(refill_units, sum)

    {period_model
    |> put_in(["refill", "actuals_meta"], meta)
    |> put_in(["refill", "actual_units"], sum)
    |> put_in(["refill", "accuracy_score"], score)
    |> put_in(["refill", "accuracy_percentage"], percentage)
    |> calculate_bin_audit({type, event}),
    new_events}
  end

  def refill_actual({type, event}, {%{"refill" => _refill} = period_model, new_events}) do
    meta = add_actuals({type, event}, period_model["refill"]["actuals_meta"] || %{})
    sum =  sum_refill_actuals(event.data["Store"], meta)
    {percentage, score} = accuracy(period_model["refill"]["refill_units"], sum)

    {period_model
    |> put_in(["refill", "actuals_meta"], meta)
    |> put_in(["refill", "actual_units"], sum)
    |> put_in(["refill", "accuracy_score"], score)
    |> put_in(["refill", "accuracy_percentage"], percentage)
    |> calculate_bin_audit({type, event}),
    new_events}
  end

  def refill_actual({type, event}, {period_model, new_events}) do
    meta = add_actuals({type, event}, period_model["refill"]["actuals_meta"] || %{})
    sum =  sum_refill_actuals(event.data["Store"], meta)

    {period_model
    |> Map.put("refill", %{})
    |> put_in(["refill", "actuals_meta"], meta)
    |> put_in(["refill", "actual_units"], sum)
    |> calculate_bin_audit({type, event}),
    new_events}
  end

  #Nike asked to reduce the actuals for NSO concepts to be reduced by 48%, because the dont refill footwear.
  def sum_refill_actuals(store_number, meta) do
    nike_stores = [
      "297", "81", "350", "100053", "60", "120022", "360", "301", "307", "382", "322", "93", "201", "240", "367", "269", "381", "19", "28", "352", "84", "323", "51", "368", "371", "86", "379", "364", "82", "325", "303", "305", "246", "237", "351", "359", "383"]
    nikeStore? = Enum.member?(nike_stores, store_number)
    case nikeStore? do
      true -> sum = sum_actuals(meta)
              adjustment = sum * 0.48
              sum - adjustment
      _ -> sum_actuals(meta)
    end
  end

# Calculates bin_audit_score for stores that do not do bin_audits, Clearance stores and Canada stores
  def calculate_bin_audit(period_model, {type, event}) do
    calc? = get_store_num({type, event})
    |> needs_bin_audit_calc

    case calc? do
      true ->
        percentage = calculate(period_model)
        period_model
        |> Map.put("bin_audit", %{})
        |> put_in(["bin_audit", "bin_percentage"], percentage)
        |> put_in(["bin_audit", "bin_score"], bin_audit_score(percentage))
      false -> period_model
    end
  end

  def get_store_num({type, event})do
    store_num = case type do
      :refill_actual -> String.to_integer(event.data["Store"])
      :pre_actual -> String.to_integer(event.data["Store"])
      :bin_audit -> String.to_integer(event.data["STORE"])
      :pre_challenge -> event.data["store_id"]
      :refill_challenge -> event.data["store_id"]
    end
    store_num
  end

  def needs_bin_audit_calc(store_num) do
    clearance_stores = [4, 21, 23, 24, 36, 44, 50, 66, 109, 134, 148, 161, 174, 204, 218, 340, 347, 377]
    canada_stores = [100049, 100050, 100052, 100053, 100088, 120002, 120010, 120018, 120022, 120026, 120027, 120029, 120030, 120031, 120032, 120034, 120035, 120039]
    Enum.member?(clearance_stores, store_num) || Enum.member?(canada_stores, store_num)
  end

  def calculate(period_model)do
    (week_percentage(period_model) / 70) * 100
  end

  def week_percentage(period_model) do
    pre_score = get_score(period_model, "pre", "pre_score")
    pre_accuracy = get_score(period_model, "pre", "accuracy_score")
    refill_score = get_score(period_model, "refill", "refill_score")
    refill_accuracy = get_score(period_model, "refill", "accuracy_score")
    pre_score + pre_accuracy + refill_score + refill_accuracy
  end

  def get_score(period_model, metric, score)do
    cond  do
      Map.has_key?(period_model, metric) ->
        cond do
          Map.has_key?(period_model[metric], score) -> period_model[metric][score]
          true -> 0
        end
      true -> 0
    end
  end

end
