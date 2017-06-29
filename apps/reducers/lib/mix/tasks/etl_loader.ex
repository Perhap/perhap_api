defmodule ETL.Loader do
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

  def decode_chunk(chunk, function) do
    # Do the Event Loading
    _results = chunk |> Enum.map(fn {line, i} ->
      event = Poison.decode!(line, as: %Event{})
      function.(event, i)
    end)
  end

  def handle_call(:stats, _, state) do
    {:reply, state, state}
  end

  def handle_call(chunk, _from, [{:ok, oks},{:fail, fails}]) do
    start_time = :calendar.datetime_to_gregorian_seconds(:calendar.universal_time())

    results = decode_chunk(chunk, fn (event, i) ->
      case sendEvent(event) do
        :ok ->
          {i, :ok}
        _ ->
          {i, :fail}
      end
      # case DB.Event.save(event) do
      #   :error ->
      #     Logger.warn "#{event.event_id}"
      #     {i, :fail}
      #   _ ->
      #     {i, :ok}
      # end
    end)

    {oks1, fails1} = count_stats(results, {0,0})

    end_time = :calendar.datetime_to_gregorian_seconds(:calendar.universal_time())
    time = end_time - start_time

    {:reply, time, [{:ok, oks+oks1},{:fail, fails+fails1}]}
  end

  defp sendEvent(event) do
    perhap_base_url = Application.get_env(:reducers, :perhap_base_url)
    url = "event/#{event.realm}/#{event.domain}/#{event.entity_id}/#{event.type}/#{event.event_id}"
    response = HTTPoison.post perhap_base_url <> "/v1/" <> url, Poison.encode!(event.meta),
    [{"Content-Type", "application/json"}]

    case response do
      {:ok, %HTTPoison.Response{status_code: 204}} ->
        # Logger.debug("success, event: #{event.event_id}")
        :ok
      _ ->
        # Logger.debug("failure, event: #{event.event_id}, reason: #{inspect(failure)}" )
        :fail
    end

  end

  # def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
  #   {:noreply, [], state}
  # end
  # def handle_info(_ref, state) do
  #   {:noreply, [], state}
  # end

  def count_stats([], accum) do
    accum
  end
  def count_stats([{_,:ok}|rest], {oks, fails}) do
    count_stats(rest, {oks+1, fails})
  end
  def count_stats([{_,:fail}|rest], {oks, fails}) do
    count_stats(rest, {oks, fails+1})
  end

end
