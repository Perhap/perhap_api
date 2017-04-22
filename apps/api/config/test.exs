use Mix.Config

config :api,
  port: 8443,
  use_ssl: true,
  ssl_options: [
    keyfile: System.cwd <> "/priv/ssl/localhost.key",
    certfile: System.cwd <> "/priv/ssl/localhost.crt"
  ]
