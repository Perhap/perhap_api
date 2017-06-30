defmodule Reducer.State do

  alias DB.Validation, as: V

  defstruct model: %{},
            new_events: [],
            deferred_events: []

  @type t :: %Reducer.State{model: map()}

  @spec stale?(list(DB.Event.t), %Reducer.State{model: map()}) :: boolean()
  def stale?(events, %Reducer.State{model: model}) do
    last_played = model |> Map.get("last_played", nil)
    case last_played do
      nil -> true
      _ ->
        events = Enum.sort(events, &(V.flip_v1_uuid(&1.event_id) <= V.flip_v1_uuid(&2.event_id)))
        V.flip_v1_uuid(List.first(events).event_id) < last_played
    end
  end

  @spec stale?(atom(), list(DB.Event.t), %Reducer.State{model: map()}) :: boolean()
  def stale?(reducer \\ nil, events, %Reducer.State{model: model} = state) do
    reducer_is_orderable = apply(reducer, :orderable, [])
    case reducer_is_orderable do
      true ->
        stale?(events, state)
      false -> # if reducers don't care about order of events, state is never stale
        false
    end
  end
end
