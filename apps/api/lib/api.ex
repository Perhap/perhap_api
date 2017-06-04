alias API.Config
alias API.Monitoring
alias API.EventHandler
alias API.EventsHandler
alias API.ModelHandler
alias API.PingHandler
alias API.StatsHandler
alias API.RootHandler
alias API.WSHandler

defmodule API do
  use Application

  def start(_type, _args) do
    start_cowboy()
    start_link()
  end

  def stop(_state) do
    :cowboy.stop_listener(:api_listener)
  end

  def start_cowboy() do
    # build our routing table
    dispatch = :cowboy_router.compile([
      {:_, [
        {"/v1/ping", PingHandler, []},
        {"/v1/event/:event_id", EventHandler, []},
        {"/v1/event/:realm/:domain/:entity_id/:type/:event_id", EventHandler, []},
        {"/v1/events/:domain/:entity_id", EventsHandler, []},
        {"/v1/model/:domain/:entity_id", ModelHandler, []},
        {"/v1/stats", StatsHandler, []},
        {"/v1/ws", WSHandler, []},
        {:_, RootHandler, []}
      ]}
    ])
    {cowboy_start_fun, protocol_opts} = case Config.get_protocol do
      :http ->  {&:cowboy.start_clear/4, nil}
      :https -> {&:cowboy.start_tls/4, get_ssl_opts()}
    end
    num_acceptors = Config.get_num_acceptors()
    {:ok, _} = cowboy_start_fun.(:api_listener, num_acceptors, ranch_tcp_opts(protocol_opts), cowboy_opts(dispatch))
  end

  def start_link() do
    import Supervisor.Spec, warn: false
    children = [
      supervisor(Task.Supervisor, [[name: Perhap.TaskSupervisor]])
    ]
    opts = [strategy: :one_for_one, name: API.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp ranch_tcp_opts(protocol_opts) do
    {raw_ip, port} = Config.get_bind_address()
    {_, ip} = :inet.parse_address(raw_ip)
    tcp_options = [
      {:ip, ip},
      {:port, port},
      {:max_connections, 16_384},
      {:backlog, 32_768},
    ]
    case protocol_opts do
      nil -> tcp_options
      _ -> tcp_options ++ protocol_opts
    end
  end

  defp cowboy_opts(dispatch) do
    %{
      env: %{dispatch: dispatch},
      middlewares: [
        Monitoring.First,
        :cowboy_router,
        :cowboy_handler,
        Monitoring.Last
      ],
      # onresponse: &API.Monitoring.Last.execute/4
      stream_handlers: [:cowboy_compress_h, :cowboy_stream_h]
    }
  end

  defp get_ssl_opts() do
    [{:cacertfile, Config.get_ssl_cacertfile()},
     {:certfile, Config.get_ssl_certfile()},
     {:keyfile, Config.get_ssl_keyfile()}]
  end

end
