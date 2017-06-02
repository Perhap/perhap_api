defmodule API.WSHandler do
  use API.Handler
  def init(req0, opts) do
    {:cowboy_websocket, req0, opts}
  end

  def websocket_init(state) do
    :erlang.start_timer(1000, self(), "Hello")
    {:ok, state}
  end

  def websocket_handle({:text, message}, state) do
    {:reply, {:text, "That's what she said! - #{message}"}, state}
  end
  def websocket_handle(_data, state) do
    {:ok, state}
  end

  def websocket_info({:timeout, _ref, message}, state) do
    :erlang.start_timer(1000, self(), "How are you?")
    {:reply, {:text, message}, state}
  end
  def websocket_info(_info, state) do
    {:ok, state}
  end
end
