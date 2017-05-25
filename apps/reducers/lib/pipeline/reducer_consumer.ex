defmodule Reducer.Consumer do
  use GenStage

  import DB.Common, only: [unit_separator: 0]
  alias DB.Event
  alias DB.Reducer.State, as: RS
  alias Reducer.State

  require Logger

  def start_link(partition) do
    # reducers = Reducer.Loader.load_all()
    # reducers = [Service.Transformer, Service.StoreIndex, Service.Store, Service.Stats, Service.PerhapStats, Service.PerhapLog, Service.Domo, Service.Challenge]
    reducers = [Service.Stats, Service.PerhapStats, Service.PerhapLog, Service.Challenge]
    initial_state = %{partition: partition, reducers: reducers}
    GenStage.start_link(__MODULE__, initial_state)
  end

  def init(initial_state = %{partition: partition, reducers: reducers}) do
    {:consumer, [reducers: reducers], subscribe_to: [{EventCoordinator, partition: partition}]}
  end

  # time to reticulate splines
  def handle_events(events, _from, state) do
    all_reducers = Keyword.get(state, :reducers)

    all_context = RS.reducer_context(events)
    run_results = Enum.map(all_context, fn({reducer_context, reducer_events}) ->
      reducer_states = Enum.reduce(all_reducers, Map.new(), fn(reducer, acc) ->
        [_|rest] = String.split(Atom.to_string(reducer), ".")
        reducer_name = rest |> Enum.map(&String.downcase(&1)) |> Enum.join(".")
        reducer_state_key = reducer_context <> unit_separator() <> reducer_name

        # Load State
        reducer_state = case RS.find(reducer_state_key) do
          :not_found -> %State{}
          db_state -> %State{model: db_state.model.data}
        end

        # Ensure not Stale
        {reducer_events, reducer_state} = case State.stale?(reducer_events, reducer_state) do
          true ->
            {domain, entity_id, _} = RS.split_key(reducer_state_key)
            indexed_events = Event.find_by_entity_domain(entity_id, domain) |> Event.find() |> Enum.map(&(&1.model))
            reducer_events_all = (reducer_events ++ indexed_events) |> Enum.uniq
            {reducer_events_all, %State{}}
          false ->
            {reducer_events, reducer_state}
        end

        # Run Reducers
        result = Map.put(acc, reducer_state_key, apply(reducer, :call, [reducer_events, reducer_state]))

        # Save Model
        reducer_state = (result |> Map.fetch!(reducer_state_key))
        %RS{state_id: reducer_state_key, data: reducer_state.model} |> RS.save

        process_new_events(reducer_state.new_events)

        # Aggregate Reducer Results
        result
      end)
    end)
    Logger.debug("Reducer Results: #{inspect(run_results)}")
    {:noreply, [], state}
  end

  # there isn't really anything to do with these yet
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    {:noreply, [], state}
  end
  def handle_info(ref, state) do
    {:noreply, [], state}
  end

  # Save and dispatch new events
  defp process_new_events(events) when is_list(events) do
    Enum.each(events, fn(event) ->
      case Event.save(event) do
        %Event{} = event ->
          EventCoordinator.async_notify(event)
          :ok
        _ ->
          :error
      end
    end)
  end

end
