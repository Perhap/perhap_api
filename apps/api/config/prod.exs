use Mix.Config

config :api,
  port: 8080,
  sync_transactions: true,
  some_key: System.get_env("SOME_KEY")
