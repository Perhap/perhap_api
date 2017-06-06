defmodule Reducer.Consumer do
  use GenStage

  import DB.Common, only: [unit_separator: 0]
  alias DB.Event
  alias DB.Reducer.State, as: RS
  alias DB.Validation, as: V
  alias Reducer.State

  require Logger

  def start_link(partition) do
    reducers = case Application.get_env(:reducers, :services) do
      :all ->
        Reducer.Loader.load_all()
      reducers when is_list(reducers) ->
        reducers
      _ ->
        []
    end
    initial_state = %{partition: partition, reducers: reducers}
    GenStage.start_link(__MODULE__, initial_state)
  end

  def init(%{partition: partition, reducers: reducers}) do
    {:consumer, [reducers: reducers], subscribe_to: [{EventCoordinator, partition: partition}]}
  end

  # time to reticulate splines
  def handle_events(events, _from, state) do
    all_reducers = Keyword.get(state, :reducers)

    all_context = RS.reducer_context(events)
    run_results = Enum.map(all_context, fn({reducer_context, reducer_events}) ->
      _reducer_states = Enum.reduce(all_reducers, Map.new(), fn(reducer, acc) ->
        # Setup
        [target_domain, _] = String.split(reducer_context, unit_separator())
        [_|rest] = String.split(Atom.to_string(reducer), ".")
        reducer_name = rest |> Enum.map(&String.downcase(&1)) |> Enum.join(".")
        reducer_domains = apply(reducer, :domains, [])

        case maybe_filter_by_domain(target_domain, reducer_domains) do
          false -> %Reducer.State{}
          true ->
            # Execution
            reducer_state_key = reducer_context <> unit_separator() <> reducer_name
            result = execute(reducer_state_key, reducer_events, reducer, acc)

            # Post Processing
            case result do
              :error -> %Reducer.State{}
              _ ->
                reducer_state = (result |> Map.fetch!(reducer_state_key))
                %RS{state_id: reducer_state_key, data: reducer_state.model} |> RS.save
                process_new_events(reducer_state.new_events)
                result
            end
        end
      end)
    end)
    Logger.debug("Reducer Results: #{inspect(run_results)}")
    {:noreply, [], state}
  end

  # there isn't really anything to do with these yet
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:noreply, [], state}
  end
  def handle_info(_ref, state) do
    {:noreply, [], state}
  end

  defp maybe_filter_by_domain(target_domain, reducer_domains) do
    case Application.get_env(:reducers, :filter_by_domain) do
      true ->
        case Enum.member?(reducer_domains, :all) do
          true -> true
          false ->
            Enum.member?(reducer_domains, String.to_atom(target_domain))
        end
      false -> true # no filter, just execute
    end
  end

  defp execute(reducer_state_key, reducer_events, reducer, acc) do
    # Load State
    reducer_state = case RS.find(reducer_state_key) do
      :not_found -> %State{}
      db_state -> %State{model: db_state.model.data}
    end

    # Ensure not Stale
    {reducer_events, reducer_state} = case State.stale?(reducer_events, reducer_state) do
      true ->
        {domain, entity_id, _} = RS.split_key(reducer_state_key)
        indexed_events = case Event.find_by_entity_domain(entity_id, domain) do
          :not_found -> []
          events -> events |> Event.find() |> Enum.filter(&(&1 != :not_found)) |> Enum.map(&(&1.model))
        end
        reducer_events_all = (reducer_events ++ indexed_events) |> Enum.uniq
        {reducer_events_all, %State{}}
      false ->
        {reducer_events, reducer_state}
    end

    # Run Reducers
    try do
      Map.put(acc, reducer_state_key, apply(reducer, :call, [reducer_events, reducer_state]))
    rescue
      error ->
        Logger.error("Problem calling reducer: #{inspect(reducer)}, #{inspect(error)},
          trace: #{inspect(:erlang.get_stacktrace())},
          with events: #{inspect(reducer_events |> Enum.map(&(&1).event_id))},
          and state: #{reducer_state_key}|#{inspect(reducer_state)}")
        :error
    end
  end

  # Save and dispatch new events
  defp process_new_events(events) when is_list(events) do
    Enum.each(events, fn(event) ->
      case V.valid_event(event) do
        false ->
          Logger.error("Reducers generated invalid event #{inspect(event)}")
          :invalid_event
        true ->
          case Event.save(event) do
            %Event{} = event ->
              EventCoordinator.async_notify(event)
            _ ->
              :error
          end
      end
    end)
  end

end
