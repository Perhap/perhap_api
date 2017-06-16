defmodule Service.Store do
  @behaviour Reducer

  @domains [:store]
  @types [:add, :delete]
  def domains, do: @domains
  def types, do: @types

  alias DB.Event
  alias Reducer.State

  import DB.Validation, only: [flip_v1_uuid: 1]

  @spec call(list(Event.t), State.t) :: State.t
  def call(events, %State{} = state) do
    {new_model, new_events} = events
    |> validate()
    |> store_reducer_recursive({state.model, []})
    %State{state | model: new_model, new_events: new_events}
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
    Enum.member?([
      "add",
      "delete"], event.type)
  end

  def event_structure({type, event}) do
    {type, event}
  end

  def event_structure(event) do
    type = String.downcase(event.type)
    data = %{
        entity_id: event.entity_id,
        domain: event.domain,
        data: event.meta,
        ordered_id: flip_v1_uuid(event.event_id)
      }
    {type, data}
  end


  def store_reducer_recursive([event | remaining_events], {model, new_events}) do
    store_reducer_recursive(remaining_events, play(event, {model, new_events}))
  end
  def store_reducer_recursive([], {model, new_events}) do
    {model, new_events}
  end

  def play({type, event}, {model, _new_events}) do
    {new_model, newer_events} =
      case type do
        "add" -> add_store(event, model)
        "delete" -> delete(event, model)
      end
    {new_model, newer_events}
  end

  def add_store(event, model) do
    _new_store =
      %{"name" => event.data["display_name"],
        "number" => event.data["store_number"],
        "district" => event.data["district"],
        "district_id" => event.data["district_id"],
        "territory" => event.data["territory"],
        "concept" => event.data["concept"],
        "subconcept" => event.data["subconcept"],
        "active" => true
       }

    { model
      |> Map.put("last_played", event.ordered_id)
      |> Map.put("active", :true)
      |> Map.put("name", event.data["display_name"] || model.name)
      |> Map.put("number", event.data["store_number"] || model.number)
      |> Map.put("district", event.data["district"] || model.district)
      |> Map.put("district_id", event.data["district_id"] || model.district_id)
      |> Map.put("territory", event.data["territory"] || model.territory)
      |> Map.put("concept", event.data["concept"] || model.concept)
      |> Map.put("subconcept", event.data["subconcept"] || model.subconcept),
    []
    }
  end

  def delete(event, model) do
    { model
        |> Map.put("last_played", event.ordered_id)
        |> Map.put("active", false),
      []
    }
  end
end
