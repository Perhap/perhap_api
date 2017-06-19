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
    case read_body(conn, "") do
      {:ok, body, conn2} -> handle_body(conn2, event, body)
      {:more, _, conn2} -> handle_badlength(conn2) # this typically won't happen
      {:timeout, _, conn2} -> Response.send(conn2, E.make(:request_timeout))
    end
  end

  # Event Body Handling
  defp read_body(conn, acc) do
    read_body_opts = %{
      length: 1048576, # chunks read in this size
      period: 10,
      timeout: 11
    }
    try do
      case :cowboy_req.read_body(conn, read_body_opts) do
        {:ok, data, conn2} -> {:ok, acc <> data, conn2};
        {:more, data, conn2} -> read_body(conn2, acc <> data)
      end
    catch
      :exit, _ -> {:timeout, acc, conn}
    end
  end

  defp handle_badlength(conn) do
    Response.send(conn, E.make(:request_too_large))
  end

  defp handle_body(conn, event, body) do
    {remote_ip, _remote_port} = :cowboy_req.peer(conn)
    json_map = JSON.decode!(body)
    ip_addr = remote_ip |> Tuple.to_list |> Enum.join(".")
    case DB.Event.save(%{event | meta: json_map, remote_ip: ip_addr}) do
      %DB.Event{} = event ->
        # coordinate: (hash & ship to self | other connected API node)
        nodes = Node.list() ++ [Node.self]
        node = :erlang.phash2({event.domain, event.entity_id}, length(nodes))
        GenServer.cast({EventCoordinator, Enum.at(nodes, node)}, {:notify, event})
        Response.send(conn, 204)
      :error ->
        Response.send(conn, E.make(:service_unavailable))
    end
  end

end
