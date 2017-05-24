defmodule Reducers do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    partitions = Application.get_env(:reducers, :partitions)

    children = [
      worker(EventCoordinator, [partitions: partitions])
    ]
    children = children ++ Enum.map(0..partitions-1, &worker(Reducer.Consumer, [&1], [id: &1]))

    opts = [strategy: :one_for_one, name: Reducers.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
