defmodule DB.ReducerStateTest do
  use ExUnit.Case
  alias DB.Event
  alias DB.Reducer.State

  doctest DB

  setup do
    events = [
      %DB.Event{domain: "challenge", entity_id: "123", event_id: "def"},
      %DB.Event{domain: "stats", entity_id: "xyz", event_id: "890"},
      %DB.Event{domain: "challenge", entity_id: "123", event_id: "abc"}
    ]
    [events: events]
  end

  test "can determine reducer context from events", context do
    assert State.reducer_context(context[:events]) == %{"challenge_123" => [
        %Event{domain: "challenge", entity_id: "123", event_id: "def"},
        %Event{domain: "challenge", entity_id: "123", event_id: "abc"}],
      "stats_xyz" => [
        %Event{domain: "stats", entity_id: "xyz", event_id: "890"}]}
  end

  test "can split reducer_state_key" do
    key = "challenge_37a2e8d4-20d7-4875-aab6-8d40e621c542_service.challenge"
    {domain, entity_id, service} = State.split_key(key)
    assert domain == "challenge"
    assert entity_id == "37a2e8d4-20d7-4875-aab6-8d40e621c542"
    assert service == "service.challenge"
  end
end
