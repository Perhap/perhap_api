use Mix.Config

import_config "../apps/*/config/config.exs"
import_config "*local.exs"

config :ssl, protocol_version: :"tlsv1.2"

config :quantum,
  global?: true,
  timezone: "America/Denver"
