alias API.Event
alias API.Error, as: E
alias API.Response
alias DB.Validation, as: V

defmodule API.EventHandler do
  use API.Handler
  def init(req0, opts) do
    method = :cowboy_req.method(req0)
    bindings = :cowboy_req.bindings(req0)
    {:ok, handle(method, bindings, req0), opts}
  end

  def handle("GET", bindings, req0) do
    Event.get(req0, bindings[:event_id])
  end
  def handle("POST", bindings, req0) do
    event = struct(DB.Event, bindings)
    case V.is_uuid_v1(event.event_id) and V.is_uuid_v4(event.entity_id) do
      true ->
        kv_time = V.extract_datetime(event.event_id)
        event = %DB.Event{event|kv_time: kv_time}
        Event.post(req0, event)
      false ->
        Response.send(req0, E.make(:invalid_id))
    end
  end
  def handle(_, _, req0) do
    req0 |> Response.send(E.make(:not_found))
  end
end
