defmodule API.Model do
  import DB.Common, only: [unit_separator: 0]

  alias API.Response
  alias API.Error, as: E

  @spec get(:cowboy_req.req(), String.t, String.t) :: :cowboy_req.req()
  def get(conn, domain, entity_id) do
    e_ctx = DB.Common.event_context(%{entity_id: entity_id, domain: domain})
    reducer_state_key = e_ctx <> unit_separator() <> "service." <> domain
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
