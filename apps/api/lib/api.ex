defmodule API do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      case Application.get_env(:api, :use_ssl) do
        false ->
          Plug.Adapters.Cowboy.child_spec(:http, API.Router, [], [port: Application.get_env(:api, :port)])
        true ->
          ssl_options = Application.get_env(:api, :ssl_options)
          cowboy_options = [
            port: Application.get_env(:api, :port),
            otp_app: :api,
            keyfile: ssl_options[:keyfile],
            certfile: ssl_options[:certfile],
          ]
          cowboy_options = case Keyword.has_key?(ssl_options, :cacertfile) do
            true -> cowboy_options ++ ssl_options[:cacertfile]
            false -> cowboy_options
          end
          Plug.Adapters.Cowboy.child_spec(:https, API.Router, [], cowboy_options)
      end
    ]
    opts = [strategy: :one_for_one, name: API.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
