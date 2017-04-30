defmodule DB do
  use Application
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # supervisor(Phoenix.PubSub.PG2, [DB.PubSub, []])
    ]

    opts = [strategy: :one_for_one, name: DB.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
