
defmodule Mix.Tasks.Bracket do
  use Mix.Task

  @shortdoc "weekly calculate bracket winners"

  require Logger

  def get_bracket_maps() do
    e_ctx = DB.Common.event_context(%{domain: "bracket", entity_id: "ae597af6-9901-405a-827d-1989dfeea4a4"})
    state_key = DB.Reducer.State.key(e_ctx, "bracket")
    state = DB.Reducer.State.find(state_key)
    _bracket_map = case state do
      :error -> Logger.info("couldn't get bracket list")
      :not_found -> Logger.info("couldn't get bracket list")
      _ -> state.model.data["bracket"]
    end
  end

  def request_store_stats(store, week) do
    perhap_base_url = Application.get_env(:reducers, :perhap_base_url)
    response = HTTPoison.get(perhap_base_url <> "/v1/model/" <>
      "stats/" <> store["entity_id"])
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: data}} ->
        {:ok, decoded_data} = Poison.decode(data)
        {score, accuracy} = total_week(decoded_data[week])
        Map.put(store, week <> "accuracy_score", accuracy)
        |> Map.put(week <> "score", score)
      {:ok, %HTTPoison.Response{status_code: code}} ->
        Logger.error("couldn't get store #{inspect(store["entity_id"])} #{inspect(store["number"])} stats with status code #{code}")
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("couldn't get store #{inspect(store["entity_id"])} stats with error #{reason}")
    end
  end

  # # generates test data
  # def request_store_stats(store, week)do
  #   Map.put(store, week <> "accuracy_score", :rand.uniform(10))
  #   |> Map.put(week <> "score", :rand.uniform(70))
  # end

  def total_week(week_stats) do
    bin_score = get_score(week_stats, "bin_audit", "bin_score")
    pre_score = get_score(week_stats, "pre", "pre_score")
    pre_accuracy = get_score(week_stats, "pre", "accuracy_score")
    refill_score = get_score(week_stats, "refill", "refill_score")
    refill_accuracy = get_score(week_stats, "refill", "accuracy_score")
    pre_accuracy_percentage = get_score(week_stats, "pre", "accuracy_percentage")
    refill_accuracy_percentage = get_score(week_stats, "refill", "accuracy_percentage")
    {bin_score + pre_score + pre_accuracy + refill_score + refill_accuracy, (abs(pre_accuracy_percentage - 1) + abs(refill_accuracy_percentage - 1))}
  end

  def get_score(week_stats, metric, score)do
    cond  do
      Map.has_key?(week_stats, metric) ->
        cond do
          Map.has_key?(week_stats[metric], score) -> week_stats[metric][score]
          true -> 0
        end
      true -> 0
    end
  end


  def run(_args \\ [])do
    Application.ensure_all_started(:db)
    bracket = get_bracket_maps()
    season = get_season()
    case bracket do
      :ok -> Logger.warn("no bracket available")
      _ -> determine_winners(bracket, season)
        |> save_bracket()
    end
  end

  def determine_winners(bracket, season)do
    {last_week, week_name, week_num} = which_week(bracket, season)
    bracket = case week_name do
      "final" -> bracket
      "week0" -> bracket
      _ -> weekly_winners = Enum.map(bracket[season <> last_week], fn(store) -> request_store_stats(store, week_num) end )
        |> sort_by_a_then_b("position", "bracket", &<=/2, &<=/2)
        |> Enum.chunk(2)
        |> Enum.map(fn(set) -> max_by_a_then_b(set, week_num <> "accuracy_score", week_num <> "score", &<=/2, &>=/2) end)
        Map.put(bracket, season <> week_name, weekly_winners)
    end
    %{"bracket" => bracket}
  end

  def save_bracket(bracket_map) do
    e_ctx = DB.Common.event_context(%{domain: "bracket", entity_id: "ae597af6-9901-405a-827d-1989dfeea4a4"})
    state_key = DB.Reducer.State.key(e_ctx, "bracket")
    DB.Reducer.State.save(
      %DB.Reducer.State{
        state_id: state_key,
        data: bracket_map
      }
    )
  end

  def max_by_a_then_b(list, a, b, order_a, order_b) do
    sort_by_a_then_b(list, a, b, order_a, order_b)
    |> hd
  end

  def sort_by_a_then_b(list, a, b, order_a, order_b) do
    sort_by_key(list, a, order_a)
    |> sort_by_key(b, order_b)
  end

  def sort_by_key(list, key, order) do
    Enum.sort_by(list, fn
      {_district, item} -> item[key]
      item -> item[key]
    end, order)
  end

  def which_week(bracket_map, season) do
    season_num = String.at(season, 6)
    weeks = Map.keys(bracket_map)
      cond do
        Enum.all?([season <> "round1", season <> "sweet16", season <> "elite8", season <> "final4", season <> "championship", season <> "champion"], fn(week) -> Enum.member?(weeks, week) end) -> {"champion", "final", ""}
        Enum.all?([season <> "round1", season <> "sweet16", season <> "elite8", season <> "final4", season <> "championship"], fn(week) -> Enum.member?(weeks, week) end) -> {"championship", "champion", "tournament" <> season_num <> "week5"}
        Enum.all?([season <> "round1", season <> "sweet16", season <> "elite8", season <> "final4"], fn(week) -> Enum.member?(weeks, week) end ) -> {"final4", "championship", "tournament" <> season_num <> "week4"}
        Enum.all?([season <> "round1", season <> "sweet16", season <> "elite8"], fn(week) -> Enum.member?(weeks, week) end ) -> {"elite8", "final4", "tournament" <> season_num <> "week3"}
        Enum.all?([season <> "round1", season <> "sweet16"], fn(week) -> Enum.member?(weeks, week) end ) -> {"sweet16", "elite8", "tournament" <> season_num <> "week2"}
        Enum.all?([season <> "round1"], fn(week) -> Enum.member?(weeks, week) end ) -> {"round1", "sweet16", "tournament" <> season_num <> "week1"}
        true -> {"not in tournament play", "week0", ""}
      end
  end

  def get_season()do
    [_elixir_string, season] = Application.get_env(:reducers, :current_season)
    |> to_string()
    |> String.downcase()
    |> String.split(".")
    season
  end

end
