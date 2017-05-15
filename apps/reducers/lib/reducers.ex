defmodule Reducers do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(EventDispatcher, [])
    ]
    children = children ++ Enum.map(1..10, &worker(Reducer.Consumer, [], [id: &1]))

    opts = [strategy: :one_for_one, name: Reducers.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
