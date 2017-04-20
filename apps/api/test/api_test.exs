defmodule APITest do
  use ExUnit.Case, async: true
  use Plug.Test
  
  doctest API

  @api_router_opts API.Router.init([])

  test "create event" do
    realm = "realm"
    domain = "domain"
    entity_id = "entity_id"
    event_type = "event_type"
    event_id = "event_id"
    fixture = "Some DATA"
    conn = conn(:post, "/v1/event/realm/#{realm}/#{domain}/#{entity_id}/#{event_type}/#{event_id}", fixture)
    |> put_req_header("content-type", "application/json")
    conn = API.Router.call(conn, @api_router_opts)
    assert conn.state == :sent
    assert conn.status == 200
  end

end
