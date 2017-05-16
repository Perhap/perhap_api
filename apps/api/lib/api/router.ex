defmodule API.Router do
  import Plug.Conn
  use Plug.Router

  plug Plug.Logger, log: :debug
  plug Plug.Parsers,
    parsers: [Plug.Parsers.JSON,
              Plug.Parsers.URLENCODED,
              Plug.Parsers.MULTIPART],
    json_decoder: Poison
  plug Plug.Monitoring

  alias API.Event
  alias API.Error, as: E
  alias API.Model
  alias API.Response
  alias DB.Validation, as: V

  case Application.get_env(:api, :use_ssl) do
    true -> plug Plug.SSL
    _ -> nil
  end

  plug :match
  plug :dispatch

  get "/v1/ping", do: Response.send(conn, 200, %{status: "OK"})

  get "/v1/event/:event_id", do: Event.get(conn, event_id)
  post "/v1/event/:realm/:domain/:entity_id/:event_type/:event_id" do
    case V.is_uuid_v1(event_id) and V.is_uuid_v4(entity_id) do
      true ->
        kv_time = V.extract_datetime(event_id)
        Event.post(conn, %DB.Event{
          realm: realm, domain: domain, entity_id: entity_id,
          type: event_type, event_id: event_id, kv_time: kv_time})
      false ->
        Response.send(conn, E.make(:invalid_id))
    end
  end

  get "/v1/events/:entity_id", do: Event.get_by_entity(conn, entity_id)

  get "/v1/model/:domain/:entity_id", do: Model.get(conn, domain, entity_id)

  get "/v1/stats", do: Stats.get(conn)

  match _ do
    Response.send(conn, E.make(:not_found))
  end
end
