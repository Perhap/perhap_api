defmodule DB.EventTest do
  use ExUnit.Case
  doctest DB

  setup do
    events = [
      %DB.Event{domain: "challenge", entity_id: "123", event_id: "def"},
      %DB.Event{domain: "stats", entity_id: "xyz", event_id: "890"},
      %DB.Event{domain: "challenge", entity_id: "123", event_id: "abc"}
    ]
    [events: events]
  end

  test "can determine domain list from events", context do
    assert [:challenge, :stats] == DB.Event.domains(context[:events])
  end

  test "can determine entity list from events", context do
    assert ["123", "xyz"] == DB.Event.entities(context[:events])
  end

  test "can determine reducer context from events", context do
    assert DB.Event.reducer_context(context[:events]) == %{"challenge_123" => [
        %DB.Event{domain: "challenge", entity_id: "123", event_id: "def"},
        %DB.Event{domain: "challenge", entity_id: "123", event_id: "abc"}],
      "stats_xyz" => [
        %DB.Event{domain: "stats", entity_id: "xyz", event_id: "890"}]}
  end
end
