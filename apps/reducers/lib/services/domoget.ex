defmodule Service.Domo do

  import Reducer.Utils
  require Logger

  def domo_service(dataset_info) do
    store_ids = get_store_ids()

    dataset_id = dataset_info["dataset_id"]
    client_id = dataset_info["client_id"]
    client_secret = dataset_info["client_secret"]
    type = dataset_info["out_going_type"]
    field_name= dataset_info["field_name"]

    domo_dataset(dataset_id, client_id, client_secret)
    |> chunk_by_store(field_name)
    |> reduce_size(type)
    |> consolidate_shared_stores(type)
    |> Enum.each(fn {store_num, chunk} ->
      send_store_chunk(store_num, get_entity_id(store_num, store_ids), chunk, type) end)

  end

  def domo_dataset(dataset_id, client_id, client_secret) do
   get_access_token(client_id, client_secret)
    |> get_dataset(dataset_id)
  end

  def get_access_token(client_id, client_secret) do
    url = "https://api.domo.com/oauth/token?grant_type=client_credentials&scope=data"
    case HTTPoison.get(url, %{}, [hackney: [basic_auth: {client_id, client_secret}]]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        response = Poison.Parser.parse!(body)
        response["access_token"]
      {:ok, %HTTPoison.Response{status_code: code}} ->
        Logger.warn("token error, status_code#{code}")
        :error
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.warn("token error, #{reason}")
        :error
    end
  end

  def get_dataset(access_token, dataset_id) do
    url = "https://api.domo.com/v1/datasets/#{dataset_id}/data?includeHeader=true&fileName=data_dump.csv"
    case HTTPoison.get(url, [{"Authorization", "bearer #{access_token}"}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      {:ok, %HTTPoison.Response{status_code: code}} ->
        Logger.warn("dataset error, status_code#{code}")
        :error
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.warn("dataset error, #{reason}")
        :error
    end
  end

  def reduce_size(dataset, type) do
    case type do
      "challenge" ->
        dataset
        |> Enum.map(fn {store, data} ->
          {store, Enum.map(data, fn(challenge) ->
             Map.take(challenge, ["Goal", "UPH", "challenge_type", "complete_units", "start_date", "store_id"]) end)}
        end)
      _ -> dataset
    end
  end


  def consolidate_shared_stores(dataset, type) do
    dataset
    |> merge_two_stores(type, "19", "297")
    |> merge_two_stores(type, "59", "298")
    |> merge_three_stores(type, "88", "299", "96")


  end

  def merge_two_stores(dataset, _type, store_1, store_2) when is_list(dataset) do
    {store_1, store_1_data} = List.keyfind(dataset, store_1, 0)
    {store_2 ,store_2_data} = List.keyfind(dataset, store_2, 0)

    new_store_data = {store_1, store_1_data ++ store_2_data}

    new_dataset = List.keydelete(dataset, store_1, 0)
    |> List.keydelete(store_2, 0)

    [new_store_data | new_dataset]
  end

  def merge_two_stores(dataset, type,  store_1, store_2) do
    case type do
      "bin_audit" -> dataset
      _ ->
        store_1_data = dataset[store_1]
        store_2_data = dataset[store_2]

        Map.drop(dataset, [store_1, store_2])
        |> Map.put(store_1, store_1_data ++ store_2_data )
    end
  end

  def merge_three_stores(dataset, _type, store_1, store_2, store_3) when is_list(dataset) do
    {store_1, store_1_data} = List.keyfind(dataset, store_1, 0)
    {store_2 ,store_2_data} = List.keyfind(dataset, store_2, 0)
    {store_3 ,store_3_data} = List.keyfind(dataset, store_3, 0)

    new_store_data = {store_1, store_1_data ++ store_2_data ++ store_3_data}

    new_dataset = List.keydelete(dataset, store_1, 0)
    |> List.keydelete(store_2, 0)
    |> List.keydelete(store_3, 0)

    [new_store_data | new_dataset]
  end

  def merge_three_stores(dataset, type, store_1, store_2, store_3) do
    store_1_data = dataset[store_1]
    store_2_data = dataset[store_2]
    store_3_data = dataset[store_3]

    new_store_data = case type do
      "bin_audit" ->
        store_1_data ++ store_3_data
      _ ->
        store_1_data ++ store_2_data ++ store_3_data
    end


    Map.drop(dataset, [store_1, store_2, store_3])
    |> Map.put(store_1, new_store_data)
  end


  def chunk_by_store(dataset, field_name)do
    dataset
    |> String.split("\n")
    |> List.delete_at(-1)
    |> CSV.decode!(headers: true, strip_fields: true)
    |> Enum.group_by(fn (x) -> x[field_name] end)
  end

  def send_store_chunk(store_num, entity_id, chunk, type)do
    case is_nil(entity_id) do
      # this occurs when a store id isn't in the store index
      true ->
        Logger.warn("#{type} event is for a invalid store: #{store_num}")
        nil
      false ->
        {_, data} =Poison.encode(%{"data" => chunk, "store" => store_num})
        event_id = gen_uuidv1()

        url = Application.get_env(:reducers, :perhap_base_url) <> "/v1/event/nike/stats/#{entity_id}/#{type}/#{event_id}"

        case HTTPoison.post(url, data, ["Content-Type": "application/json"], []) do
          {:ok, %HTTPoison.Response{status_code: 204 }} ->
            :ok
          {:ok, %HTTPoison.Response{status_code: code}} ->
            Logger.warn("upload #{type} event from domo error, status_code#{code}")
            :error
          {:error, %HTTPoison.Error{reason: reason}} ->
            Logger.warn("upload #{type} event from domo error, #{reason}")
            :error
        end
      end
  end

  def get_entity_id(store_id, stores) do
    store = to_string(store_id)
    stores[store]
  end

  def get_store_ids() do
    perhap_base_url = Application.get_env(:reducers, :perhap_base_url)
    url = perhap_base_url <> "/v1/model/storeindex/100077bd-5b34-41ac-b37b-62adbf86c1a5"
    {:ok, response} = case Mix.env do
      :test ->
        HTTPoison.get(url, [], hackney: [:insecure])
      _ ->
        HTTPoison.get(url)
    end
    {:ok, body} = Poison.decode(response.body)
    body["stores"]
  end

end
