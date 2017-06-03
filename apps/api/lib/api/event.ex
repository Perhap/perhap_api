defmodule API.Event do
  alias API.Response
  alias API.Error, as: E

  @spec get(:cowboy_req.req(), String.t) :: :cowboy_req.req()
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

  @spec get_by_entity(:cowboy_req.req(), String.t, String.t) :: :cowboy_req.req()
  def get_by_entity(conn, entity_id, domain) do
    case DB.Event.find_by_entity_domain(entity_id, domain) do
      :not_found -> Response.send(conn, E.make(:not_found))
      :error -> Response.send(conn, E.make(:service_unavailable))
      results -> Response.send(conn, 200, results)
    end
  end

  @spec post(:cowboy_req.req(), DB.Event.t) :: :cowboy_req.req()
  def post(conn, %DB.Event{} = event) do
    {:ok, body, _} = :cowboy_req.read_body(conn)
    {remote_ip, _remote_port} = :cowboy_req.peer(conn)
    json_map = JSON.decode!(body)
    ip_addr = remote_ip |> Tuple.to_list |> Enum.join(".")
    case DB.Event.save(%{event | meta: json_map, remote_ip: ip_addr}) do
      %DB.Event{} = event ->
        EventCoordinator.async_notify(event)
        Response.send(conn, 204)
      :error ->
        Response.send(conn, E.make(:service_unavailable))
    end
  end

end
