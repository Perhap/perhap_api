defmodule API.Event do
  alias API.Response
  alias API.Error, as: E

  @spec get(Plug.Conn, String.t) :: Plug.Conn
  def get(conn, event_id) do
    case DB.Event.find(event_id, false) do
      :not_found -> Response.send(conn, E.make(:not_found))
      :error -> Response.send(conn, E.make(:service_unavailable))
      %{model: %DB.Event{} = event} ->
        Response.send(conn, 200, event)
      _ ->
        Response.send(conn, E.make(:model_not_implemented))
    end
  end

  @spec get_by_entity(Plug.Conn, String.t) :: Plug.Conn
  def get_by_entity(conn, _entity_id) do
    Response.send(conn, E.make(:operation_not_implemented))
  end

  @spec post(Plug.Conn, DB.Event.t) :: Plug.Conn
  def post(conn, %DB.Event{} = event) do
    ip_addr = conn.remote_ip |> Tuple.to_list |> Enum.join(".")
    case DB.Event.save(%{event | meta: conn.body_params, remote_ip: ip_addr}) do
      %DB.Event{} = event ->
        EventDispatcher.async_notify(event)
        Response.send(conn, 204)
      :error ->
        Response.send(conn, E.make(:service_unavailable))
    end
  end

  @spec bulk(Plug.Conn, String.t) :: Plug.Conn
  def bulk(conn, _realm) do
    Response.send(conn, 204)
  end

end
