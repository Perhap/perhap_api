defmodule EventCoordinator do
  use GenStage

  alias DB.Event

  @max_buffer_size 20000

  require Logger

  def start_link(state) do
    GenStage.start_link(__MODULE__, state, name: __MODULE__)
  end

  def sync_notify(event, timeout \\ 5000) do
    GenStage.call(__MODULE__, {:notify, event}, timeout)
  end

  def async_notify(event) do
    GenStage.cast(__MODULE__, {:notify, event})
  end

  def init({:partitions, partitions}) do
    {
      :producer,
      %{queue: :queue.new, demand: 0, count: 0},
      dispatcher: {GenStage.PartitionDispatcher,
        partitions: 0..partitions-1,
        hash: &partition_by_event/1},
      buffer_size: @max_buffer_size
    }
  end

  def partition_by_event(%Event{domain: domain, entity_id: entity_id} = event) do
    partitions = Application.get_env(:reducers, :partitions)
    {event, :erlang.phash2({domain, entity_id}, partitions)}
  end

  def handle_call({:notify, event}, from, state) do
    queue = :queue.in({from, event}, Map.get(state, :queue))
    state = Map.put(state, :queue, queue)
    dispatch(state, [])
    # case :queue.len(queue) do
    #   5 ->
    #     dispatch(state, [])
    #   _ ->
    #     {:reply, :ok, [], state}
    # end
  end

  # get information on the broadcaster state
  def handle_call(:state, _from, state) do
    {:reply, state, [], state}
  end

  def handle_cast({:notify, event}, state) do
    queue = :queue.in({:async, event}, Map.get(state, :queue))
    state = Map.put(state, :queue, queue)
    dispatch(state, [])
  end

  def handle_demand(incoming_demand, state) do
    Logger.debug("Handle Demand: #{inspect(incoming_demand)}")
    state = Map.put(state, :demand, Map.get(state, :demand) + incoming_demand)
    dispatch(state, [])
  end

  defp dispatch(%{demand: 0} = state, events) do
    {:noreply, Enum.reverse(events), state}
  end
  defp dispatch(state, events) do
    queue = Map.get(state, :queue)
    demand = Map.get(state, :demand)
    count = Map.get(state, :count)
    case :queue.out(queue) do
      {{:value, {:async, event}}, queue} ->
        state = state
             |> Map.put(:demand, demand - 1)
             |> Map.put(:count, count + 1)
             |> Map.put(:queue, queue)
        dispatch(state, [event | events])
      {{:value, {from, event}}, queue} ->
        GenStage.reply(from, :ok)
        state = state
             |> Map.put(:demand, demand - 1)
             |> Map.put(:count, count + 1)
             |> Map.put(:queue, queue)
        dispatch(state, [event | events])
      {:empty, queue} ->
        {:noreply, Enum.reverse(events), Map.put(state, :queue, queue)}
    end
  end
end
