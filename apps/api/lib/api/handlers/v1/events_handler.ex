alias API.Event
alias API.Error, as: E
alias API.Response

defmodule API.EventsHandler do
  use API.Handler
  def init(req0, opts) do
    method = :cowboy_req.method(req0)
    bindings = :cowboy_req.bindings(req0)
    {:ok, handle(method, bindings, req0), opts}
  end

  def handle("GET", bindings, req0) do
    Event.get_by_entity(req0, bindings[:entity_id], bindings[:domain])
  end
  def handle(_, _, req0) do
    req0 |> Response.send(E.make(:not_found))
  end
end
