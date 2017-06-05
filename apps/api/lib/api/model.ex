defmodule API.Model do
  alias API.Response
  alias API.Error, as: E
  alias DB.Common

  @spec get(:cowboy_req.req(), String.t, String.t) :: :cowboy_req.req()
  def get(conn, domain, entity_id) do
    e_ctx = Common.event_context(%{entity_id: entity_id, domain: domain})
    reducer_state_key = DB.Reducer.State.key(e_ctx, domain)
    case DB.Reducer.State.find(reducer_state_key, false) do
      :not_found -> Response.send(conn, E.make(:not_found))
      :error -> Response.send(conn, E.make(:service_unavailable))
      %{model: %DB.Reducer.State{} = state} ->
        Response.send(conn, 200, state.data)
      _ ->
        Response.send(conn, E.make(:model_not_implemented))
    end
  end

end
