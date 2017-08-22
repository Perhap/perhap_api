defmodule EventTest do
  use ExUnit.Case, async: true
  import API.Test.Helper

  doctest API

  setup do
    event = generate_event("challenge_start.json")
    on_exit fn ->
      DB.Event.delete(event.event_id)
      DB.Event.delete_entity_domain_index(event.entity_id, event.domain)
      :ok
    end
    [event: event]
  end

  test "create & read an event", context do
    e = context[:event]
    meta_raw = JSON.encode!(e.meta)

    %{status: status} = post(meta_raw, "/v1/event/#{e.realm}/#{e.domain}/#{e.entity_id}/#{e.type}/#{e.event_id}")
    assert status == 204

    %{status: status, body: _body} = get("/v1/event/#{e.event_id}")
    assert status == 200
  end

  test "lookup events by entity_id", context do
    wait_until fn ->
      e = context[:event]
      DB.Event.save(e)
      %{status: status, headers: _, body: body} = get("/v1/events/#{e.domain}/#{e.entity_id}")
      assert status == 200
      assert (JSON.decode!(body) |> List.first) == e.event_id
      DB.Event.delete(e.event_id)
    end
  end

end
