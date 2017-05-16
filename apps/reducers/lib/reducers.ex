defmodule Reducers do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(EventDispatcher, [])
    ]
    max_consumers = Application.get_env(:reducers, :consumers)
    children = children ++ Enum.map(1..max_consumers, &worker(Reducer.Consumer, [], [id: &1]))

    opts = [strategy: :one_for_one, name: Reducers.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
