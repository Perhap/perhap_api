require Logger

defmodule Service.Stats do
  @behaviour Reducer

  alias DB.Event
  alias Reducer.State

  @domains [:stats]
  @orderable false
  @types [:bin_audit, :actuals, :challenge]
  def domains, do: @domains
  def types, do: @types
  def orderable, do: @orderable

  @spec call(list(Event.t), State.t) :: State.t
  def call(events, %State{} = state) when is_list(events) do
    new_model = events
    |> validate()
    |> stats_reducer_recursive(state.model)
    %State{state | model: new_model, new_events: []}
  end

  def stats_reducer_recursive([], model), do: model
  def stats_reducer_recursive([event | remaining_events], model) do
    stats_reducer_recursive(remaining_events, play(event, model))
  end

  def play(event, model) do
    data = event.meta["data"]
    store_num = event.meta["store"]
    type = String.to_existing_atom(event.type)
    preped_data = data_prep(data, type)
    apply(__MODULE__, type, [model, preped_data])
    |> accuracy()
    |> calc_sub_bin_audit(store_num)
  end

  def correct_type?(event) do
    Enum.member?([
      "actuals",
      "bin_audit",
      "challenge",
      ], event.type)
  end

  def validate(event_list) do
    Enum.filter(event_list, fn(event) -> correct_type?(event) end)
  end

  def data_prep(meta, :bin_audit)do
    meta
    |> remove_nulls("DATE")
    |> filter_on_date("DATE")
    |> sort_by_time_period("DATE")
  end

  def data_prep(meta, :challenge)do
    meta
    |> filter_on_date("start_date")
    |> sort_by_time_period("start_date")
  end

  def data_prep(meta, :actuals)do
    meta
    |> remove_nulls("Count")
    |> Enum.reject(fn (row) -> String.contains?(row["Count"], "#")  end)
    |> filter_on_date("Week")
    |> sort_by_time_period("Week")
  end

  def remove_nulls(data_list, field_name) do
    Enum.reject(data_list, fn (row) -> row[field_name]== "\\N" end)
  end

  def filter_on_date(data_list, date_field_name)do
    time_periods = Application.get_env(:reducers, Application.get_env(:reducers, :current_periods))
    {_start_name, start_times} = hd(time_periods)
    start_time = start_times.start_time

    {_end_name, end_times} = List.last(time_periods)
    end_time = end_times.end_time

    Enum.filter(data_list, fn (row) -> date(row[date_field_name]) > start_time end)
    |> Enum.filter(fn (row) -> date(row[date_field_name]) < end_time end)
  end




  def sort_by_time_period(filtered_meta, date_field) do
    time_periods = Application.get_env(:reducers, Application.get_env(:reducers, :current_periods))
    filtered_meta
    |> Enum.group_by(fn(row)-> find_period(row, time_periods, date_field) end)
  end

  def find_period(row, season_periods, date_field) do
    timestamp = date(row[date_field])
    {period, _data} = season_periods
    |>  Enum.find({:out_of_season, "data"}, fn {_period, %{:start_time => start_time, :end_time => end_time}} -> timestamp >= start_time and timestamp <= end_time end)
    period
  end

  def merge_models(model, new_model)do
    Map.merge(model, new_model, fn _K, v1, v2 ->
      Map.merge(v1, v2, fn _K, v1, v2 ->
        Map.merge(v1, v2)
      end)
    end)
  end


  def actuals(model, meta) do
    new_model = Map.new(meta
    |> Enum.map(fn {period, list_of_metrics} ->
        {period, Enum.group_by(list_of_metrics, fn(metric) -> metric["Metrics"]end)}
      end)
    |> Enum.map(fn {period, data} -> {period, calculate_actuals(data)}end))
    merge_models(model, new_model)
  end

  def calculate_actuals(data)do
    Map.new(
    Enum.map(data, fn{metric, lines} ->
      case metric do
        "Actual Receipts" -> {"pre",
          %{"actual_units" => Enum.reduce(lines, 0, fn (line, acc) ->
            case Float.parse(line["Count"]) do
              {count, _ } -> count + acc
              :error -> acc
            end
          end)}}
        "Actual Units Sold" -> {"refill",
          %{"actual_units" => Enum.reduce(lines, 0, fn (line, acc) ->
            case Float.parse(line["Count"]) do
              {count, _ } ->
                case reduce_refill_actuals?(line["Store"]) do
                  true -> count * 0.52 + acc
                  _ -> count + acc
                end
              :error -> acc
            end
          end)}}
      end
    end))
  end

    #Nike asked to reduce the actuals for NSO concepts to be reduced by 48%, because they dont refill footwear.
    def reduce_refill_actuals?(store_number) do
      nike_stores = [
        "297", "81", "350", "100053", "60", "120022", "360", "301", "307", "382", "322", "93", "201", "240", "367", "269", "381", "19", "28", "352", "84", "323", "51", "368", "371", "86", "379", "364", "82", "325", "303", "305", "246", "237", "351", "359", "383"]
      Enum.member?(nike_stores, store_number)
    end


  def challenge(model, meta) do
    new_model = Map.new(
    meta
    |> Enum.map(fn {period, challenges} ->
        {period, Enum.map(challenges, fn(challenge) ->
          type = case challenge["challenge_type"] do
            "apparel" -> "pre"
            "equipment" -> "pre"
            "footwear" -> "pre"
            "product refill" -> "refill"
            _ -> :reject
          end
          Map.take(challenge, ["Goal", "UPH", "complete_units"])
          |> Map.put("challenge_type", type)
        end)
        |> Enum.group_by(fn(challenge) -> challenge["challenge_type"]end)
      }
    end)
    |> Enum.map(fn {period, data} -> {period, calc_challenge(data)}end))
    merge_models(model, new_model)
  end


  def calc_challenge(data)do
    Map.new(Enum.map(data, fn{type, lines} ->
      score = Enum.reduce(lines, %{"units" => 0, "percentage_sum" => 0, "count" => 0}, fn (line, acc)
        -> case {Float.parse(line["Goal"]), Float.parse(line["UPH"]), Float.parse(line["complete_units"])} do
          {:error, _, _} -> acc
          {_, :error, _} -> acc
          {_, _, :error} -> acc
          {{goal_uph, _}, {uph, _}, {units, _}} ->
            percent = uph/goal_uph
            %{"units" => acc["units"] + units,
              "percentage_sum" => acc["percentage_sum"] + percent,
              "count" => acc["count"] + 1
            }
        end
      end)
      {type,
      case {score["count"], type} do
        {0, _} -> %{}
        {_, :reject} -> %{}
        {_, "pre"} ->
           Map.put(score, "pre_percentage", score["percentage_sum"] / score["count"])
        |> Map.put("pre_score", percentage_score(score["percentage_sum"] / score["count"]))
        |> Map.drop(["percentage_sum", "count"])
        {_, "refill"} ->
           Map.put(score, "refill_percentage", score["percentage_sum"] / score["count"])
        |> Map.put("refill_score", percentage_score(score["percentage_sum"] / score["count"]))
        |> Map.drop(["percentage_sum", "count"])
      end}

    end))
    |> Map.drop([:reject])
  end

    def accuracy(model)do
      Map.new(model
      |> Enum.map(fn {period, data} ->
          {period,  Map.new(Enum.map(data, fn {type, model}-> {type, calc_accuracy(model)} end))} end))
    end

    def calc_accuracy(%{"actual_units" => actual_units, "units" => app_units} = model)do
      case app_units do
        0 -> model
        _ ->
          Map.put(model, "accuracy_percentage", app_units/actual_units)
          |> Map.put("accuracy_score", accuracy_score(app_units/actual_units))
      end
    end
    def calc_accuracy(model), do: model

    def bin_audit(model, meta) do
      new_model = Map.new(meta
      |> Enum.map(fn {period, data} -> {period, %{"bin_audit" => calc_bin_audit(data)}}end))
      merge_models(model, new_model)
    end

    def calc_bin_audit(lines)do
      model = Enum.reduce(lines, %{"bin_percentage" => 0, "bin_score" => 0, "count" => 0}, fn (line, acc) ->
       case Float.parse(line["BIN_PERCENTAGE"]) do
         {bin_percentage, _} ->
           acc
           |> Map.put("count", acc["count"] + 1)
           |> Map.put("bin_percentage", bin_percentage + acc["bin_percentage"])
           |> Map.put("bin_score", bin_audit_score((bin_percentage + acc["bin_percentage"])/ (acc["count"] + 1)))
         _ -> acc
       end
     end)
     Map.drop(model, ["count"])
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

  # Calculates bin_audit_score for stores that do not do bin_audits, Clearance stores and Canada stores
    def calc_sub_bin_audit(model, store_num) do
      case needs_bin_audit_calc(store_num) do
        true ->
          Map.new(Enum.map(model, fn {period, period_model} ->
          percentage = calculate(period_model)
          {period, period_model
          |> Map.put("bin_audit", %{})
          |> put_in(["bin_audit", "bin_percentage"], percentage)
          |> put_in(["bin_audit", "bin_score"], bin_audit_score(percentage))} end))
        false -> model
      end
    end


    def needs_bin_audit_calc(store_num) do
      clearance_stores = ["4", "21", "23", "24", "36", "44", "50", "66", "109", "134", "148", "161", "174", "204", "218", "340", "347", "377"]
      canada_stores = ["100049", "100050", "100052", "100053", "100088", "120002", "120010", "120018", "120022", "120026", "120027", "120029", "120030", "120031", "120032", "120034", "120035", "120039"]
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

end
