defmodule APITest do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest API

  @api_router_opts API.Router.init([])

  setup do
    {uuid_v1, _} = :uuid.get_v1(:uuid.new(self(), :erlang))
    event_id = :uuid.uuid_to_string(uuid_v1)
    entity_id = :uuid.uuid_to_string(:uuid.get_v4(:strong))
    on_exit fn ->
      :ok
    end
    [event_id: event_id, entity_id: entity_id]
  end

  test "create challenge event", context do
    {realm, domain, entity_id, event_type} = {
      "company", "challenge", context[:entity_id], "start"}
    event_id = context[:event_id]
    fixture = load_fixture("challenge_start.json")
    conn = conn(:post, "https://example.com/v1/event/#{realm}/#{domain}/#{entity_id}/#{event_type}/#{event_id}", fixture)
    |> put_req_header("content-type", "application/json")
    conn = API.Router.call(conn, @api_router_opts)
    assert conn.state == :sent
    assert conn.status == 204
  end

  @spec load_fixture(String.t) :: binary()
  def load_fixture(fixture_file) do
    {:ok, binary} = File.read "test/fixtures/" <> fixture_file
    binary
  end

end
