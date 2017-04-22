defmodule APITest do
  use ExUnit.Case, async: true
  use Plug.Test

  doctest API

  @api_router_opts API.Router.init([])

  test "create challenge event" do
    realm = "company"
    domain = "challenge"
    entity_id = "uuid_v4"
    event_type = "state"
    event_id = "uuid_v1"
    fixture = load_fixture("challenge.json")
    conn = conn(:post, "https://example.com/v1/event/#{realm}/#{domain}/#{entity_id}/#{event_type}/#{event_id}", fixture)
    |> put_req_header("content-type", "application/json")
    conn = API.Router.call(conn, @api_router_opts)
    assert conn.state == :sent
    assert conn.status == 204
  end

  def load_fixture(fixture_file) do
    {:ok, binary} = File.read "test/fixtures/" <> fixture_file
    binary
  end

end
