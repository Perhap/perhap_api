use Mix.Config

config :reducers,
  partitions: System.schedulers_online * 4,
  perhap_base_url: "https://perhap.bigsquidapp.com"
