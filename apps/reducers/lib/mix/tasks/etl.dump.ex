defmodule Mix.Tasks.Etl.Dump do
  use Mix.Task
  @shortdoc "Dump data from Riak to a file"
  @preferred_cli_env :dev

  alias DB.Event
  require Logger

  def run(argv) do
    IO.puts ("MIX ENV: #{Mix.env}")
    [file|rest] = argv
    Application.ensure_all_started(:db)
    max_concurrency = System.schedulers_online * 4
    start_pool(max_concurrency)
    event_bucket = Event.bucket
    {:ok, keys} = Riak.Bucket.keys(event_bucket)
    result = keys |> Stream.chunk(50, 50, [])
    results = result |> Enum.map(fn chunk ->
      # spawn_link(fn() -> pool_load(%{chunk: chunk, file: file, parent: self()}) end)
      Task.async(fn() -> pool_load(%{chunk: chunk, file: file}) end)
    end)
    results |> Enum.each(&Task.await(&1, :infinity))
  end

  def do_work(chunk, file) do
    Logger.debug("Grabbing Another Chunk: #{inspect(self)}")
    ETL.Extract.process(chunk, file)
  end

  defp pool_load(%{chunk: chunk, file: file} = map) do
    :poolboy.transaction(
      pool_name(), fn(pid) ->
        Logger.debug("Grabbing Another Chunk: #{inspect(self)}")
        time = :gen_server.call(pid, map, :infinity)
        stats = :gen_server.call(pid, :stats, :infinity)
        Logger.debug("#{inspect(stats)}:#{inspect(time)}")
      end,
      :infinity)
  end

  defp pool_name(), do: :loader_pool

  defp poolboy_config(max_concurrency) do
    [
      {:name, {:local, pool_name()}},
      {:worker_module, ETL.Extract},
      {:size, max_concurrency},
      {:max_overflow, max_concurrency / 4}
    ]
  end

  defp start_pool(max_concurrency) do
    import Supervisor.Spec, warn: false
    children = [
      :poolboy.child_spec(pool_name(), poolboy_config(max_concurrency), [])
    ]
    opts = [strategy: :one_for_one, name: ETL.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
