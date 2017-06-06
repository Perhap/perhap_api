defmodule Mix.Tasks.Etl.Load do
  use Mix.Task
  @shortdoc "Load data from file to Riak"
  @preferred_cli_env :dev

  require Logger

  def run(argv) do
    Application.ensure_all_started(:db)
    IO.puts ("MIX ENV: #{Mix.env}; #{inspect(self())}")
    [file|_] = argv
    start_pool()
    tasks = file
    |> File.stream!
    |> Stream.with_index
    |> Stream.chunk(2, 2, [])
    |> Enum.map(fn chunk ->
      Task.async(fn() ->
        IO.puts ("Task: #{inspect(self())}")
        pool_load(chunk)
      end)
    end)
    tasks |> Enum.map(&Task.await(&1)) |> IO.inspect
  end

  defp pool_load(chunk) do
    :poolboy.transaction(pool_name(), fn(pid) ->
      time = :gen_server.call(pid, chunk, :infinity)
      stats = :gen_server.call(pid, :stats, :infinity)
      Logger.debug("#{inspect(stats)}:#{inspect(time)}")
    end, :infinity)
  end

  defp pool_name(), do: :loader_pool

  defp poolboy_config() do
    [
      {:name, {:local, pool_name()}},
      {:worker_module, ETL.Loader},
      {:size, 300},
      {:max_overflow, 50}
    ]
  end

  defp start_pool() do
    import Supervisor.Spec, warn: false
    children = [
      supervisor(Task.Supervisor, [[name: Perhap.TaskSupervisor]]),
      :poolboy.child_spec(pool_name(), poolboy_config(), [])
    ]
    opts = [strategy: :one_for_one, name: ETL.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
