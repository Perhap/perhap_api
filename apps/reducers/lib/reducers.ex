defmodule Reducers do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(EventBroadcaster, []),
      worker(Reducer.Consumer, [])
    ]

    opts = [strategy: :one_for_one, name: Reducers.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
