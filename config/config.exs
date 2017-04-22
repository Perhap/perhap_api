use Mix.Config

import_config "../apps/*/config/config.exs"
import_config "*local.exs"

config :ssl, protocol_version: :"tlsv1.2"

config :logger,
        backends: [:console],
        utc_log: true,
        level: :warn,
        truncate: 4096

# config :logger,
#   backends: [{LoggerFileBackend, :error_log}]
#   # utc_log: true,
#   # compile_time_purge_level: :info,
#   # truncate: 4096
#
# config :logger, :error_log,
#   path: "log/error.log",
#   level: :error

# config :quantum,
#   global?: true,
#   timezone: "America/Denver"
