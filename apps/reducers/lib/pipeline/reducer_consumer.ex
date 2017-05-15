defmodule Reducer.Consumer do
  use GenStage

  import DB.Common, only: [unit_separator: 0]
  alias DB.Event
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
    pipeline = Keyword.get(state, :reducers)

    all_context = Event.reducer_context(events)
    run_results = Enum.map(all_context, fn({reducer_context, reducer_events}) ->
      reducer_states = Enum.reduce(pipeline, Map.new(), fn(reducer, acc) ->
        [_|rest] = String.split(Atom.to_string(reducer), ".")
        reducer_name = rest |> Enum.map(&String.downcase(&1)) |> Enum.join(".")
        reducer_state_key = reducer_context <> unit_separator() <> reducer_name
        reducer_state = %Reducer.State{} # TODO load reducer state here
        # could save reducer state in consumer state temp, as long as cleanup happens
        Map.put(acc, reducer_state_key, apply(reducer, :call, [reducer_events, reducer_state]))
        # TODO save reducer state here
      end)
    end)
    # or save reducer state here
    Logger.info("Reducer Results: #{inspect(run_results)}", perhap_only: 1)
    {:noreply, [], state}
  end

end
