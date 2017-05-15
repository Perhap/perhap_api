defmodule Reducer.Consumer do
  use GenStage

  import DB.Common, only: [unit_separator: 0]
  alias DB.Event
  alias DB.Reducer.State, as: RS
  require Logger

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(_) do
    reducers = Reducer.Loader.load_all()
    {:consumer, [reducers: reducers], subscribe_to: [EventBroadcaster]}
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

        # Load Model TODO Handle DB Errors
        reducer_state = case RS.find(reducer_state_key) do
          :not_found -> %Reducer.State{}
          db_state -> %Reducer.State{model: db_state.model.data["model"]}
        end

        # Run Reducers
        result = Map.put(acc, reducer_state_key, apply(reducer, :call, [reducer_events, reducer_state]))

        # Save Model
        reducer_state = (result |> Map.fetch!(reducer_state_key))
        %RS{state_id: reducer_state_key, data: reducer_state.model} |> RS.save

        # Process New Events
        Logger.info("New Events: #{inspect(reducer_state.new_events)}", perhap_only: 1)

        # Aggregate Reducer Results
        result
      end)
    end)
    # or save reducer state here
    Logger.info("Reducer Results: #{inspect(run_results)}", perhap_only: 1)
    {:noreply, [], state}
  end

end
