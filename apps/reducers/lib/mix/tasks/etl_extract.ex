defmodule ETL.Extract do
  use GenServer

  alias DB.Event

  require Logger

  def start_link([]) do
    :gen_server.start_link(__MODULE__, [], [])
  end

  def init(_) do
    state = [{:ok, 0},{:fail, 0}]
    {:ok, state}
  end

  def handle_call(:stats, _, state) do
    {:reply, state, state}
  end

  def process(chunk, file) do
    # Do the Key processing
    results = Enum.map(chunk, fn event_id ->
      result = Event.find(event_id).model
      log_result(result, file)
      case result do
        :not_found ->
          Logger.warn "#{event_id}"
          {event_id, :fail}
        _ ->
          {event_id, :ok}
      end
    end)
  end

  def handle_call(%{chunk: chunk, file: file} = map, _from, [{:ok, oks},{:fail, fails}]) do
    start_time = :calendar.datetime_to_gregorian_seconds(:calendar.universal_time())

    results = process(chunk, file)

    {oks1, fails1} = count_stats(results, {0,0})

    end_time = :calendar.datetime_to_gregorian_seconds(:calendar.universal_time())
    time = end_time - start_time

    {:reply, time, [{:ok, oks+oks1},{:fail, fails+fails1}]}
  end

  def count_stats([], accum) do
    accum
  end
  def count_stats([{_,:ok}|rest], {oks, fails}) do
    count_stats(rest, {oks+1, fails})
  end
  def count_stats([{_,:fail}|rest], {oks, fails}) do
    count_stats(rest, {oks, fails+1})
  end

  defp log_result(results, file) do
    {:ok, file} = File.open(file, [:append])
    save_result(file, results)
    File.close(file)
  end
  defp save_result(file, %Event{} = event) do
    json = Poison.encode!(event)
    IO.binwrite(file, "#{json}\n")
  end
end
