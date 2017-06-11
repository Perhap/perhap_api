require Logger

defmodule API.WSHandler do
  use API.Handler
  def init(req0, opts) do
    {:cowboy_websocket, req0, opts}
  end

  def websocket_init(state) do
    :gproc.reg({:p, :l, "ws-sockets"}, %{open_time: System.monotonic_time(), pid: self()})
    {:ok, state}
  end

  def websocket_handle({:text, message}, state) do
    %{"domain" => domain, "entity" => entity} = JSON.decode!(message)
    :gproc.reg({:p, :l, "ws-#{domain}-#{entity_id}"}, %{open_time: System.monotonic_time(), pid: self()})
    {:reply, {:text, "OK"}, state}
  end
  def websocket_handle(data, state) do
    Logger.warn("Received unexpected message: #{inspect(data)}")
    {:ok, state}
  end

  # :gproc.send({:p, :l, "ws-sockets"}, map) trigger broadcast to ws_info
  # :gproc.send({:p, :l, "ws-domain-entity_id"}, map) trigger broadcast to ws_info
  # map = %{some_state: "exists"}
  # :gproc.send({:p, :l, "ws-challenge-37a2e8d4-20d7-4875-aab6-8d40e621c542"}, map)
  # def websocket_info({:timeout, _ref, message}, state) do
  #   :erlang.start_timer(1000, self(), "How are you?")
  #   {:reply, {:text, message}, state}
  # end
  def websocket_info({:EXIT, _ref, :killed}, state) do
    {:ok, state}
  end
  def websocket_info(%{} = r_state, state) do
    json = Poison.encode!(r_state)
    {:reply, {:text, json}, state}
  end
  def websocket_info(info, state) do
    Logger.warn("Received unexpected broadcast message: #{inspect(info)}")
    {:ok, state}
  end
end
