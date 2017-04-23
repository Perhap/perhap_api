use Mix.Config

import_config "../apps/*/config/config.exs"
import_config "*local.exs"

config :ssl, protocol_version: :"tlsv1.2"

config :logger,
  backends: [
    {FileLoggerBackend, :error_log},
    {FileLoggerBackend, :access_log}],
  utc_log: true,
  compile_time_purge_level: :debug,
  truncate: 4096

config :logger, :access_log,
  path: System.cwd <> "/log/access.log",
  level: :info

config :logger, :error_log,
  path: System.cwd <> "/log/error.log",
  level: :error
