defmodule API.Router do
  import Plug.Conn
  use Plug.Router

  plug :match
  plug :dispatch

  get "host/:host/challenges/:entity_id/:event_type/:event_id" do
    conn = fetch_query_params(conn)
    send_resp(conn, 200, Poison.encode!(%{
      host: host,
      entity_id: entity_id,
      event_type: event_type,
      event_id: event_id
    }))
  end

  match _ do
    send_resp(conn, 404, "Oops! You've touched upon a bad route, Dirty Finger")
  end
end
