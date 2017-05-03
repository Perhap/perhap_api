use Mix.Config

config :db,
  url: 'perhap-prod-load-1.bigsquid.com',
  unit_separator: "\x1f"

config :pooler,
  [pools: [
    [name: :riakprod1,
     group: :riak,
     max_count: 256,
     init_count: 256,
     start_mfa: {Riak.Connection, :start_link, ['perhap-lb1.bigsquidapp.com', 8087]}
    ]
  ]]
