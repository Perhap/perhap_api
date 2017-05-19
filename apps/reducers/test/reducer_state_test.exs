defmodule Reducer.State.Test do
  use ExUnit.Case, async: true
  import Reducer.Test.Helper
  import DB.Validation, only: [flip_v1_uuid: 1]

  alias DB.Event
  alias Reducer.State

  test "state staleability" do
    [e1, e2, e3, e4, e5] = [gen_uuidv1(), gen_uuidv1(), gen_uuidv1(), gen_uuidv1(), gen_uuidv1()]
    [fe1, _, fe3, _, _] = [flip_v1_uuid(e1), flip_v1_uuid(e2), flip_v1_uuid(e3), flip_v1_uuid(e4), flip_v1_uuid(e5)]

    events = [e2, e3, e4] |> Enum.map(&%Event{event_id: &1})
    state = %State{model: %{"last_played" => fe3}}

    # Test older events invalidate state
    assert true == State.stale?(events, state)
    assert true == State.stale?([%Event{event_id: e1}], state)

    # Test a new event do not invalidate state
    assert false == State.stale?([%Event{event_id: e5}], state)

    # Test that more new events do not invalidate state
    state = %State{state | model: %{state.model | "last_played" => fe1}}
    assert false == State.stale?(events, state)
    assert false == State.stale?([%Event{event_id: e5}], state)

    # Test repeat event does not invalidate state
    assert false == State.stale?([%Event{event_id: e1}], state)
  end

end
