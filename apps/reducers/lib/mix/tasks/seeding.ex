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
    Enum.map(store_number_map, fn {k, v} -> request_store_info(v) end)
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
        Logger.info("couldn't get store #{store_entity_id} info with status code #{code}")
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("couldn't get store #{store_entity_id} info with error #{reason}")
    end
  end

  def request_store_stats(store_info_list) when is_list(store_info_list) do
    Enum.map(store_info_list, fn store -> request_store_stats(store) end)
  end
  def request_store_stats(store) do
    perhap_base_url = Application.get_env(:reducers, :perhap_base_url)
    response = HTTPoison.get(perhap_base_url <> "/v1/model/" <>
      "stats/" <> store["entity_id"])
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: data}} ->
        {:ok, decoded_data} = Poison.decode(data)
        Map.put(store, "stats", clean_up_stats(decoded_data["stats"]))
      {:ok, %HTTPoison.Response{status_code: code}} ->
        Logger.info("couldn't get store #{inspect(store["entity_id"])} stats with status code #{code}")
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("couldn't get store #{inspect(store["entity_id"])} stats with error #{reason}")
    end
  end

  def clean_up_stats(stats) do
    Enum.map(stats, fn{week, week_stats} -> {week, total_week(week_stats)} end)
    |> Map.new()
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


  def sort_stores_into_districts(store_info_list) do
    Enum.sort_by(store_info_list, fn store-> store["district"] end)
    |> Enum.chunk_by(fn store-> store["district"] end)
    |> Enum.map(fn district -> {hd(district)["district"], district} end)
    |> Map.new()
  end



end
