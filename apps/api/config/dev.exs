use Mix.Config

config :api,
  port: 4500,
  sync_transactions: true,
  some_key: "there is a world beyond our own, that is where the jedi live"

# See:  https://github.com/kafkaex/kafka_ex/blob/master/config/config.exs
config :kafka_ex,
  disable_default_worker: true,
  consumer_group: :no_consumer_group,
  brokers: [
    {"localhost", 9092}
  ],
  use_ssl: false,
  ssl_options: [
    cacertfile: System.cwd <> "/ssl/ca-cert",
    certfile: System.cwd <> "/ssl/cert.pem",
    keyfile: System.cwd <> "/ssl/key.pem"
  ]
