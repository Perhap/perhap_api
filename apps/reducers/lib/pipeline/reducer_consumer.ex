defmodule Reducer.Consumer do
  use GenStage

  import DB.Common, only: [unit_separator: 0]
  alias DB.Event
  alias DB.Reducer.State, as: RS
  alias Reducer.State

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(_) do
    reducers = Reducer.Loader.load_all()
    {:consumer, [reducers: reducers], subscribe_to: [EventDispatcher]}
  end

  # time to reticulate splines
  def handle_events(events, _from, state) do
    all_reducers = Keyword.get(state, :reducers)

    all_context = Event.reducer_context(events)
    run_results = Enum.map(all_context, fn({reducer_context, reducer_events}) ->
      reducer_states = Enum.reduce(all_reducers, Map.new(), fn(reducer, acc) ->
        [_|rest] = String.split(Atom.to_string(reducer), ".")
        reducer_name = rest |> Enum.map(&String.downcase(&1)) |> Enum.join(".")
        reducer_state_key = reducer_context <> unit_separator() <> reducer_name

        reducer_state = case RS.find(reducer_state_key) do
          :not_found -> %State{}
          db_state -> %State{model: db_state.model.data}
        end

        reducer_state = case State.stale?(reducer_events, reducer_state) do
          true -> %State{}
          false -> reducer_state
        end

        # Run Reducers
        result = Map.put(acc, reducer_state_key, apply(reducer, :call, [reducer_events, reducer_state]))

        # Save Model
        reducer_state = (result |> Map.fetch!(reducer_state_key))
        %RS{state_id: reducer_state_key, data: reducer_state.model} |> RS.save

        # Process New Events
        process_new_events(reducer_state.new_events)

        # Aggregate Reducer Results
        result
      end)
    end)
    # or save reducer state here
    # Logger.debug("Reducer Results: #{inspect(run_results)}")
    {:noreply, [], state}
  end

  defp process_new_events(events) when is_list(events) do
    Enum.each(events, fn(event) ->
      case Event.save(event) do
        %Event{} = event ->
          EventDispatcher.async_notify(event)
          :ok
        _ ->
          :error
      end
    end)
  end

end
