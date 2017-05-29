use Mix.Config

config :db,
  unit_separator: "\x1f"

config :pooler,
  [pools: [
    [name: :riakprod1,
     group: :riak,
     max_count: 64,
     init_count: 32,
     start_mfa: {Riak.Connection, :start_link, ['perhap-lb1.bigsquidapp.com', 8087]}
    ]
  ]]
