defmodule API.Router do
  import Plug.Conn
  use Plug.Router

  plug Plug.Logger
  plug Plug.Parsers,
    parsers: [Plug.Parsers.JSON,
              Plug.Parsers.URLENCODED,
              Plug.Parsers.MULTIPART],
    json_decoder: Poison

  alias API.Event

  case Application.get_env(:api, :use_ssl) do
    true -> plug Plug.SSL
    _ -> nil
  end

  plug :match
  plug :dispatch

  get "/v1/ping" do
    send_resp(conn, 200, "OK")
  end

  post "/v1/event/:realm/:domain/:entity_id/:event_type/:event_id",
       do: Event.post(conn)

  post "/v1/events/:realm",
       do: Event.bulk(conn)

  match _ do
    send_resp(conn, 404, "Invalid Route")
  end
end
