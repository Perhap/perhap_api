defmodule Service.Transformer do
  @behaviour Reducer

  @domains [:transformer]
  @types [:pre_challenge_transform, :refill_challenge_transform]
  def domains, do: @domains
  def types, do: @types

  alias DB.Event
  alias Reducer.State
  import Reducer.Utils

  @spec call(list(Event.t), State.t) :: State.t
  def call(events, state)do
    {model, new_events} = Enum.filter(events, fn(event) -> correct_type?(event) end)
     |> transformer_recursive({state.model, []})
    %State{model: model, new_events: new_events}
  end

  def correct_type?(event) do
    Enum.member?([
      "pre_challenge_transform", "refill_challenge_transform"], event.type)
  end

  # API CALL TO STORE INDEX HERE
  def stores do
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

  def get_entity_id(stores, store_number)do
    store = to_string(store_number)
    stores[store]
  end

  def transformer_recursive([], {model, new_events}), do: {model, new_events}
  def transformer_recursive([event | remaining_events], {model, new_events}) do
    transformer_recursive(remaining_events, transform_event(event, {model, new_events}))
  end

  def transform_event(%Event{type: "pre_challenge_transform"} = event, {model, new_events})  do
    {model, [event
    |> Map.put(:domain, "stats")
    |> Map.put(:type, "pre_challenge")
    |> Map.put(:event_id, gen_uuidv1())
    |> Map.put(:remote_ip, "127.0.0.1")
    |> Map.put(:entity_id, get_entity_id(stores(), event.meta["store_id"])) | new_events]}
  end

  def transform_event(%Event{type: "refill_challenge_transform"} = event, {model, new_events}) do
    {model, [event
    |> Map.put(:domain, "stats")
    |> Map.put(:type, "refill_challenge")
    |> Map.put(:event_id, gen_uuidv1())
    |> Map.put(:remote_ip, "127.0.0.1")
    |> Map.put(:entity_id, get_entity_id(stores(), event.meta["store_id"])) | new_events]}
  end

end
