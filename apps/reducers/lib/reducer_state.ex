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
      nil -> false
      _ ->
        events = Enum.sort(events, &(V.flip_v1_uuid(&1.event_id) <= V.flip_v1_uuid(&2.event_id)))
        V.flip_v1_uuid(List.first(events).event_id) < last_played
    end
  end
end
