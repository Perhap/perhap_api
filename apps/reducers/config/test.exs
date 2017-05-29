use Mix.Config

config :reducers,
  partitions: System.schedulers_online * 2,
  perhap_base_url: "https://localhost:8443"
