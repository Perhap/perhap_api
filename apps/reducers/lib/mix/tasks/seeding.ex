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
        Map.put(store, "score", calculate_score(decoded_data["stats"]))
      {:ok, %HTTPoison.Response{status_code: code}} ->
        Logger.error("couldn't get store #{inspect(store["entity_id"])} #{inspect(store["number"])} stats with status code #{code}")
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("couldn't get store #{inspect(store["entity_id"])} stats with error #{reason}")
    end
  end

  def calculate_score(stats) do
    Enum.map(stats, fn{week, week_stats} -> {week, total_week(week_stats)} end)
    |> Enum.reduce(0, fn({_week, score}, acc) -> score + acc end)
  end

  def total_week(week_stats) do
    bin_score = get_score(week_stats, "bin_audit", "bin_score")
    pre_score = get_score(week_stats, "pre", "pre_score")
    pre_accuracy = get_score(week_stats, "pre", "accuracy_score")
    refill_score = get_score(week_stats, "refill", "refill_score")
    refill_accuracy = get_score(week_stats, "refill", "accuracy_score")
    bin_score + pre_score + pre_accuracy + refill_score + refill_accuracy
  end

  def get_score(week_stats, metric, score)do
    cond  do
      Map.has_key?(week_stats, metric) ->
        cond do
          Map.has_key?(week_stats[metric], [score]) -> week_stats[metric][score]
          true -> 0
        end
      true -> 0
    end
  end

  def sort_stores_into_districts(store_stats_list) do
    # Enum.map(store_stats_list, fn store -> IO.inspect(store)end)
    store_stats_list
    |> Enum.sort_by(fn store -> store["district"] end)
    |> Enum.chunk_by(fn store -> store["district"] end)
    |> Enum.map(fn district -> {hd(district)["district"], district} end)
    |> Map.new()
  end

  def top_store_per_district(district_map)do
    {Enum.map(district_map, fn {district, stores} -> {district, Enum.max_by(stores, fn(store)-> store["score"] end )} end)
    |> Enum.reject(fn {district, _stores} -> district == "test" end)
    |> Map.new(),

    Enum.map(district_map, fn {district, stores} -> Enum.max_by(stores, fn(store)-> store["score"] end ) end)}
  end

  def sort_stores_by_score(store_stats_list) do
    store_stats_list
    |> Enum.sort_by(fn store -> store["score"] end, &>=/2)
  end

  def find_wildcards(store_stats_list, {district_map, district_list}) when length(district_list) < 32 and length(district_list) > 27 do
    wildcard_num = case length(district_list) do
      28 -> "wildcard1"
      29 -> "wildcard2"
      30 -> "wildcard3"
      31 -> "wildcard4"
    end
    [hd | tail] = store_stats_list
    cond do
      Enum.member?(district_list, hd) ->
        find_wildcards(tail, {district_map, district_list})
      true -> find_wildcards(tail, {Map.put(district_map, wildcard_num, hd), Enum.concat(district_list, [hd])})
    end
  end
  def find_wildcards(store_stats_list, {district_map, district_list}) when length(district_list) == 32 do
    district_map
  end
  def find_wildcards(store_stats_list, {district_map, district_list}) do
    Logger.error("error getting stores by district, number of districts not 28 - 32")
  end



end
