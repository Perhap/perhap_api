defmodule Mix.Tasks.Seeding do
  use Mix.Task

  @shortdoc "Initialize bracket with seeding"

  require Logger


  # defp getStoreList() do
  #   #API call to get last hash set
  #   perhap_base_url = Application.get_env(:reducers, :perhap_base_url)
  #   response = HTTPoison.get!(perhap_base_url <> "/v1/model/" <>
  #     "storeindex/100077bd-5b34-41ac-b37b-62adbf86c1a5")
  #
  #     case response do
  #       %HTTPoison.Response{status_code: 200, body: data} ->
  #         {:ok, decoded_data} = Poison.decode(data)
  #         request_store_info(decoded_data["stores"])
  #       %HTTPoison.Response{status_code: 404} ->
  #         Logger.info("couldn't get store list"))
  #     end
  # end
  #
  # defp request_store_info(store_number_map) when is_map(store_number_map) do
  #   Enum.each(store_number_map, (k,v) -> request_store_info(v) end)
  # end
  #
  # defp request_store_info(store_entity_id) do
  #
  # end

end
