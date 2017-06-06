defmodule EventTest do
  use ExUnit.Case, async: true
  import API.Test.Helper

  doctest API

  setup do
    {uuid_v1, _} = :uuid.get_v1(:uuid.new(self(), :erlang))
    event_id = :uuid.uuid_to_string(uuid_v1)
    entity_id = :uuid.uuid_to_string(:uuid.get_v4(:strong))
    on_exit fn ->
      DB.Event.delete(to_string(event_id))
      :ok
    end
    [event_id: event_id, entity_id: entity_id]
  end

  test "create challenge event", context do
    {realm, domain, entity_id, type} = {
      "company", "challenge", context[:entity_id], "start"}
    event_id = context[:event_id]
    fixture = load_fixture("challenge_start.json")

    %{status: status} = post(fixture, "/v1/event/#{realm}/#{domain}/#{entity_id}/#{type}/#{event_id}")
    assert status == 204
  end

end
