

defmodule Mix.Tasks.Seeding do
  use Mix.Task

  @shortdoc "Initialize bracket with seeding"

  require Logger


  def get_store_list() do
    perhap_base_url = Application.get_env(:reducers, :perhap_base_url)
    response = HTTPoison.get(perhap_base_url <> "/v1/model/" <>
      "storeindex/100077bd-5b34-41ac-b37b-62adbf86c1a5")
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: data}} ->
        {:ok, decoded_data} = Poison.decode(data)
        decoded_data["stores"]
      {:ok, %HTTPoison.Response{status_code: code}} ->
        Logger.info("couldn't get store list with status code #{code}")
      {:error, reason} ->
        Logger.error("couldn't get store list with error #{reason}")
    end
  end

  def request_store_info(store_number_map) when is_map(store_number_map) do
    Enum.map(store_number_map, fn {_k, id} -> request_store_info(id) end)
  end
  def request_store_info(store_entity_id) do
    perhap_base_url = Application.get_env(:reducers, :perhap_base_url)
    response = HTTPoison.get(perhap_base_url <> "/v1/model/" <>
      "store/" <> store_entity_id)
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: data}} ->
        {:ok, decoded_data} = Poison.decode(data)
        Map.put(decoded_data, "entity_id", store_entity_id)
      {:ok, %HTTPoison.Response{status_code: code}} ->
        Logger.error("couldn't get store #{store_entity_id} info with status code #{code}")
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("couldn't get store #{store_entity_id} info with error #{reason}")
    end
  end

  def request_store_stats(store_info_list) when is_list(store_info_list) do
    Enum.map(store_info_list, fn store -> request_store_stats(store) end)
    |> Enum.reject(fn store -> store == :ok end)
  end
  def request_store_stats(store) do
    perhap_base_url = Application.get_env(:reducers, :perhap_base_url)
    response = HTTPoison.get(perhap_base_url <> "/v1/model/" <>
      "stats/" <> store["entity_id"])
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: data}} ->
        {:ok, decoded_data} = Poison.decode(data)
        {score, accuracy} = calculate_score(decoded_data["stats"])

        Map.put(store, "accuracy_score", accuracy)
        |> Map.put("score", score)
      {:ok, %HTTPoison.Response{status_code: code}} ->
        Logger.error("couldn't get store #{inspect(store["entity_id"])} #{inspect(store["number"])} stats with status code #{code}")
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("couldn't get store #{inspect(store["entity_id"])} stats with error #{reason}")
    end
  end

  # # generates test data
  # def request_store_stats(store) do
  #   Map.put(store, "accuracy_score", :rand.uniform(10))
  #   |> Map.put("score", :rand.uniform(70))
  # end

  def run(_args \\ []) do
    Application.ensure_all_started(:db)
    stats = get_store_stats_pipeline()
    top_stores_by_district_pipeline(stats)
    |> wildcard_pipeline(stats)
    |> set_up_bracket()
    |> save_bracket()
  end

  def get_store_stats_pipeline()do
    get_store_list()
    |> request_store_info
    |> request_store_stats
  end

  def top_stores_by_district_pipeline(store_stats_list) do
    store_stats_list
    |> sort_stores_into_districts
    |> top_store_per_district
    |> assign_rank_number
  end

  def wildcard_pipeline(district_tuple, store_stats_list) do
    store_stats_list
    |> sort_stores_by_score
    |> find_wildcards(district_tuple, 28)
    |> Map.values
  end

  def set_up_bracket(top_32) do
    list_of_32 = sort_top_32(top_32)
    east = east_bracket(list_of_32)
    |> recursive_add_seed(1, "east")
    west = west_bracket(list_of_32)
    |> recursive_add_seed(1, "west")
    %{get_season() <> "round1" => east ++ west}
  end

  def save_bracket(bracket_map) do
    e_ctx = DB.Common.event_context(%{domain: "bracket", entity_id: "ae597af6-9901-405a-827d-1989dfeea4a4"})
    state_key = DB.Reducer.State.key(e_ctx, "bracket")
    old_state= DB.Reducer.State.find(state_key)
    bracket_map =   case old_state do
        :error -> %{"bracket" => bracket_map}
        :not_found -> %{"bracket" => bracket_map}
        _ -> Map.merge(old_state.model.data["bracket"], bracket_map)
      end
    DB.Reducer.State.save(
      %DB.Reducer.State{
        state_id: state_key,
        data: bracket_map
      }
    )
  end

  def get_season()do
    [_elixir_string, season] = Application.get_env(:reducers, :current_season)
    |> to_string()
    |> String.downcase()
    |> String.split(".")
    season
  end

  def weeks_to_include()do
    [_elixir_string, season] = Application.get_env(:reducers, :current_season)
    |> to_string()
    |> String.downcase()
    |> String.split(".")
    number_of_weeks = Application.get_env(:reducers, :current_season_length)

    week_string(season, number_of_weeks)
  end

  def week_string(season, number) when number > 1 do
    [season <> "week" <> to_string(number) | week_string(season, number-1)]
  end
  def week_string(season, number) when number == 1 do
    [season <> "week" <> to_string(number)]
  end

  def calculate_score(stats) do
    weeks_scores = Enum.filter(stats, fn{week, _stats} -> Enum.member?(weeks_to_include(), week)end)
    |> Enum.map(fn{week, week_stats} -> {week, total_week(week_stats)} end)
    {Enum.reduce(weeks_scores, 0, fn({_week, {score, _accuracy}}, acc) -> score + acc end),
    Enum.reduce(weeks_scores, 0, fn({_week, {_score, accuracy}}, acc) -> accuracy + acc end)}
  end

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

  def sort_stores_into_districts(store_stats_list) do
    store_stats_list
    |> Enum.sort_by(fn store -> store["district"] end)
    |> Enum.chunk_by(fn store -> store["district"] end)
    |> Enum.map(fn district -> {hd(district)["district"], district} end)
    |> Enum.reject(fn {district, _stores} -> district == "test" || district == "East Canada" end)
    |> Map.new()
  end

  def top_store_per_district(district_map)do
    {Enum.map(district_map,
    fn
      {"West Canada", stores} -> {"West Canada",
        Enum.filter(stores, fn(store) -> Enum.member?([120034], store["number"]) end)
        |> max_by_a_then_b("accuracy_score", "score", &<=/2, &>=/2)
        }
      {district, stores} -> {district, max_by_a_then_b(stores, "accuracy_score", "score", &<=/2, &>=/2)}
  end),
    Enum.map(district_map, fn {_district, stores} -> Enum.max_by(stores, fn(store)-> store["score"] end ) end)}
  end

  def sort_stores_by_score(store_stats_list) do
    store_stats_list
    |> sort_by_a_then_b("accuracy_score", "score", &<=/2, &>=/2)
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

  def assign_rank_number({district_tuple_list, district_list}) do
    ranked_district_map = sort_by_a_then_b(district_tuple_list, "accuracy_score", "score", &<=/2, &>=/2)
    |> recursive_add_rank(1)
    |> Map.new()

    {ranked_district_map, district_list}
  end

  def recursive_add_rank([hd | tail], rank) do
    [add_rank_to_map(hd, rank) | recursive_add_rank(tail, rank + 1)]
  end
  def recursive_add_rank([], _rank) do
    []
  end


  def add_rank_to_map({district, store_map}, rank) do
    {district, Map.put(store_map, "rank", rank)}
  end


  def find_wildcards(store_stats_list, {district_map, district_list}, rank) when length(district_list) < 32 and length(district_list) > 26 do
    wildcard_num = case length(district_list) do
      27 -> "wildcard1"
      28 -> "wildcard2"
      29 -> "wildcard3"
      30 -> "wildcard4"
      31 -> "wildcard5"
    end
    [hd | tail] = store_stats_list
    cond do
      Enum.member?(district_list, hd) ->
        find_wildcards(tail, {district_map, district_list}, rank)
      true -> find_wildcards(tail, {Map.put(district_map, wildcard_num, Map.put(hd, "rank", rank)), [HD | district_list]}, rank + 1)
    end
  end
  def find_wildcards(_store_stats_list, {district_map, district_list}, _rank) when length(district_list) == 32 do
    district_map
  end
  def find_wildcards(_store_stats_list, {_district_map, district_list}, _rank) do
    Logger.error("error getting stores by district, number of districts #{inspect(length(district_list))} must be between 27 and 32")
  end

  def recursive_add_seed([hd | tail], rank, bracket) do
    [add_seed_to_map(hd, rank, bracket) | recursive_add_seed(tail, rank + 1, bracket)]
  end
  def recursive_add_seed([], _rank, _bracket) do
    []
  end

  def add_seed_to_map(store_map, seed, bracket) do
    Map.put(store_map, "seed", seed)
    |> Map.put("bracket", bracket)
    |> Map.put("position", positions_in_bracket(seed))
  end


  def sort_top_32(list_of_32)do
    Enum.sort_by(list_of_32, fn store -> store["rank"] end)
  end

  def east_bracket(list_of_32) do
    Enum.filter(list_of_32, fn store -> rem(store["rank"], 2)==0 end)
  end

  def west_bracket(list_of_32) do
    Enum.filter(list_of_32, fn store -> rem(store["rank"], 2)==1 end)
  end

  def positions_in_bracket(seed)do
    case seed do
      1-> "a"
      16-> "b"
      8-> "c"
      9-> "d"
      5-> "e"
      12-> "f"
      4-> "g"
      13-> "h"
      6-> "i"
      11-> "j"
      3-> "k"
      14-> "l"
      7-> "m"
      10-> "n"
      2-> "o"
      15-> "p"
    end
  end

end
