import Reducer.Utils

defmodule Reducer.State.Test do
  use ExUnit.Case, async: true
  import DB.Validation, only: [flip_v1_uuid: 1]

  alias DB.Event
  alias Reducer.State

  setup do
    [e1, e2, e3, e4, e5] = [gen_uuidv1(), gen_uuidv1(), gen_uuidv1(), gen_uuidv1(), gen_uuidv1()]
    flipped = [flip_v1_uuid(e1), flip_v1_uuid(e2), flip_v1_uuid(e3), flip_v1_uuid(e4), flip_v1_uuid(e5)]
    [events: [e1, e2, e3, e4, e5], flipped: flipped]
  end

  test "reducer orderablity has precident over state staleness", context do
    [_, e2, e3, e4, _] = context[:events]
    events = [e2, e3, e4] |> Enum.map(&%Event{event_id: &1})

    # Test any event invalidates empty state
    assert true == State.stale?(events, %State{})

    # Test reducers may override staleness
    assert false == State.stale?(Service.PerhapLog, events, %State{})
  end

  test "state staleability", context do
    [e1, e2, e3, e4, e5] = context[:events]
    [fe1, _, fe3, _, _] = context[:flipped]

    events = [e2, e3, e4] |> Enum.map(&%Event{event_id: &1})
    state = %State{model: %{"last_played" => fe3}}

    # Test any event invalidates empty state
    assert true == State.stale?(events, %State{})

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
