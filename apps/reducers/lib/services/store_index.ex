defmodule Service.StoreIndex do
  @behaviour Reducer
  @types [:replace]

  def types do
    @types
  end

  alias DB.Event
  alias Reducer.State

  require Logger

  import DB.Validation, only: [flip_v1_uuid: 1]

  @spec call(list(Event.t), State.t) :: State.t
  def call(events, %State{} = state) do
    events
    |> validate()
    |> store_index_reducer_recursive(state)
  end

  def uuidv1({_type, event}) do
    event.ordered_id
  end

  def validate(event_list) do
    Enum.filter(event_list, fn(event) -> correct_type?(event) end)
    |> Enum.map(fn(event) -> event_structure(event) end)
    |> MapSet.new()
    |> MapSet.to_list()
    |> sorts_events()
  end

  def sorts_events(event_list)do
    Enum.sort(event_list, &(uuidv1(&1) < uuidv1(&2)))
  end

  def correct_type?({_type, _event}) do
    true
  end

  def correct_type?(event) do
    Enum.member?(
      [ "replace" ], event.type)
  end

  def event_structure({type, event}) do
    {type, event}
  end

  def event_structure(event) do
    type = String.downcase(event.type)
    data =
      %{
        entity_id: event.entity_id,
        domain: event.domain,
        data: event.meta,
        ordered_id: flip_v1_uuid(event.event_id)
       }
    {type, data}
  end


  def store_index_reducer_recursive([event | remaining_events], state) do
    store_index_reducer_recursive(remaining_events, play(event, state))
  end

  def store_index_reducer_recursive([], state) do
    state
  end

  def play({type, event}, state) do
    {new_model, newer_events} =
      case type do
        "replace" -> replace_all(event, state.model)
      end
    %State{model: new_model,
      new_events: state.new_events ++ newer_events}
  end

  defp replace_all(event, model) do
    {model
        |> Map.put("last_played", event.ordered_id)
        |> Map.put("stores", event.data["stores"])
        |> Map.put("hashes", event.data["hashes"]),
      []
    }
  end
end
