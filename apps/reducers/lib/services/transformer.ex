defmodule Service.Transformer do
  @behaviour Reducer

  @types [:pre_challenge_transform, :refill_challenge_transform]
  def types do
    @types
  end

  alias DB.Event
  alias Reducer.State


  def correct_type?(event) do
    Enum.member?([
      "pre_challenge_transform", "refill_challenge_transform"], event.type)
  end


  # API CALL TO STORE INDEX HERE
  def stores do
    %{
      360 => "d68e938f-c597-4ada-9f7a-5bcad3dbbaaf",
      93242 => "8222fa94-8e1f-42a7-b1db-b8ad7b535545",
    }
  end

  def get_entity_id(stores, store_number)do
    stores[store_number]
  end

  # @spec call(list(Event.t), State.t) :: State.t
  # def call(events, model)do
  #   Enum.filter(events, fn(event) -> correct_type?(event) end)
  #   %State{model: model, new_events: Enum.map(events, fn(event)-> transform_event(event) end)}
  # end

  @spec call(list(Event.t), State.t) :: State.t
  def call(events, model)do
    model
  end

  def transform_event(event)do
    event
    |> Map.put(:domain, "stats")
    |> Map.put(:entity_id, get_entity_id(stores(), event.meta["store_id"]) )
  end

end
