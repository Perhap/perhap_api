use Mix.Config

config :db,
  url: 'localhost'

  config :logger, :access_log,
    path: System.cwd <> "/log/access.log",
    metadata: [:function, :module],
    level: :debug

  config :logger, :error_log,
    path: System.cwd <> "/log/error.log",
    metadata: [:function, :module],
    level: :error
