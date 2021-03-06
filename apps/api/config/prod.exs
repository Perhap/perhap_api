use Mix.Config

config :api,
  [
    network: [
      {:protocol, :https},
      {:bind, {'0.0.0.0', 443}},
      {:acceptors, System.schedulers_online * 4},
    ],
    ssl: [
      {:keyfile, System.cwd <> "/priv/ssl/__bigsquidapp_com.key"},
      {:certfile, System.cwd <> "/priv/ssl/__bigsquidapp_com.crt"},
      {:cacertfile, System.cwd <> "/priv/ssl/__bigsquidapp_com.ca-bundle"}
    ]
  ]
