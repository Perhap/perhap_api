defmodule Service.Domo do
  @behaviour Reducer

  import DB.Validation, only: [flip_v1_uuid: 1]

  alias DB.Event
  alias Reducer.State


  @domains [:domo]
  @types [:pull]
  def domains, do: @domains
  def types, do: @types

  def correct_type?(event) do
    Enum.member?([
      "pull"], event.type)
  end


  @spec call(list(Event.t), State.t) :: State.t
  def call(events, state)do
    {model, new_events} = Enum.filter(events, fn(event) -> correct_type?(event) end)
     |> domo_service_recursive({state.model, []})
    %State{model: model, new_events: new_events}
  end


  def domo_service_recursive([], {model, new_events}), do: {model, new_events}
  def domo_service_recursive([event | remaining_events], {model, new_events}) do
    domo_service_recursive(remaining_events, domo_service(event, {model, new_events}))
  end


  def domo_service(event, state) do
    model = state.model
    meta = event.meta
    dataset_id = meta["dataset_id"]
    client_id = meta["client_id"]
    client_secret = meta["client_secret"]
    type = meta["out_going_type"]
    last_played = event.event_id |> flipper

    domo_dataset(dataset_id, client_id, client_secret)
      |> hash_file(model, type)
      |> return_model_and_events(last_played)


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
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:err, "404:Not Found"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:err, reason}
    end

  end

  def get_dataset(access_token, dataset_id) do
    url = "https://api.domo.com/v1/datasets/#{dataset_id}/data?includeHeader=true&fileName=data_dump.csv"

    case HTTPoison.get(url, [{"Authorization", "bearer #{access_token}"}]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:err, "404:Not Found"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:err, reason}
    end

  end

  def hash_file(body, model, type) do
    hash_state = is_empty?(model)
    [col_heads | values] = String.split(body, "\n", parts: 2)
    file = String.split(to_string(values), "\n")
    file |> Enum.reduce({[], col_heads, type, hash_state}, &reducer/2)
  end

  def reducer(row, {events, col_heads, type, hash_state}) when row != "" do
    {new_events, col_heads, type, new_hash_state} =
      case Donethat.new?(row, hash_state) do
        {true, new_hash_state} ->
          {[make_event(col_heads, type, row) | events], col_heads, type, new_hash_state}
        {_, new_hash_state} ->
          {events, col_heads, type, new_hash_state}
      end
    {new_events, col_heads, type, new_hash_state}
  end

  def reducer(row, {events, col_heads, type, hash_state}) do
    {events, col_heads, type, hash_state}
  end

  def is_empty?(model) when map_size(model) == 0 do
    Donethat.empty_state
  end

  def is_empty?(model) do
    model[:hash_state]
  end

  def make_event(col_heads, type, row) do
    [store | _t] = String.split(row, ",", parts: 2)
    meta = build_meta_map(col_heads, row)
    event = %Event{domain: "stats",
                      meta: meta,
                      entity_id: get_entity_id(meta["STORE"] || meta["Store"]),
                      event_id: gen_event_id(),
                      realm: "nike",
                      remote_ip: "127.0.0.1",
                      type: type}
    event
  end

  def build_meta_map(col_heads, row) do
    [dc] = CSV.decode([col_heads], separator: ?,)
      |> Enum.to_list
    [dr] = CSV.decode([row], separatot: ?,)
      |> Enum.to_list
    Enum.zip(dc, dr)
      |> Map.new
  end

  def get_entity_id(store_id) do
    store = to_string(store_id)
    perhap_base_url = Application.get_env(:reducers, :perhap_base_url)
    url = perhap_base_url <> "/v1/model/storeindex/100077bd-5b34-41ac-b37b-62adbf86c1a5"
    {:ok, response} = case Mix.env do
      :test ->
        HTTPoison.get(url, [], hackney: [:insecure])
      _ ->
        HTTPoison.get(url)
    end
    {:ok, body} = Poison.decode(response.body)
    body["stores"][store]
  end

  def gen_event_id() do
    {uuid_v1, _} = :uuid.get_v1(:uuid.new(self(), :erlang))
    event_id = :uuid.uuid_to_string(uuid_v1)
    event_id
  end

  def return_model_and_events({new_events, _col_heads, _type, new_hash_state}, last_played) do
    model = Map.put(%{}, :last_played, last_played)
      |> Map.put(:hash_state, new_hash_state)
    {model, new_events}
  end

  def flipper(uuidv1) do
    [time_low, time_mid, time_high, node_hi, node_low] = String.split(uuidv1, "-")
    time_high <> "-" <> time_mid <> "-" <> time_low <> "-" <> node_hi <> "-" <> node_low
  end
end
