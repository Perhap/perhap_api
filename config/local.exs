use Mix.Config

config :api,
  enabled: true

# config :reducers,
#   services: [Service.Stats, Service.PerhapStats, Service.PerhapLog, Service.Challenge, Service.StoreIndex],

config :logger, :access_log,
  path: System.cwd <> "/log/access.log",
  metadata: [:function, :module],
  level: :info

config :logger, :error_log,
  path: System.cwd <> "/log/error.log",
  metadata: [:function, :module],
  level: :error
