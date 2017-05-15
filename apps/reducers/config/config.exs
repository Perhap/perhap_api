use Mix.Config

import_config "#{Mix.env}.exs"

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
