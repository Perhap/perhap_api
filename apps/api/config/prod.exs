use Mix.Config

config :api,
  port: 443,
  use_ssl: true,
  ssl_options: [
    keyfile: System.cwd <> "/priv/ssl/__bigsquidapp_com.key",
    certfile: System.cwd <>"/priv/ssl/__bigsquidapp_com.crt",
    cacertfile: System.cwd <> "/priv/ssl/__bigsquidapp_com.ca-bundle",
  ]
