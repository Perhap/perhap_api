use Mix.Config

config :api,
  enabled: true

# config :reducers,
#   services: [Service.Stats, Service.PerhapStats, Service.PerhapLog, Service.Challenge, Service.StoreIndex],

config :logger, :access_log,
  path: System.cwd <> "/log/access.log",
  metadata: [:function, :module],
  level: :debug

config :logger, :error_log,
  path: System.cwd <> "/log/error.log",
  metadata: [:function, :module],
  level: :error

config :reducers, :domo_creds,
  client_secret: "domo_secret",
  client_id: "domo_id"
