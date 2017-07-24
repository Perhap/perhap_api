use Mix.Config

config :db,
  unit_separator: "\x1f"

config :pooler,
  [pools: [
    [name: :riakprod1,
     group: :riak,
     max_count: 512,
     init_count: 256,
     start_mfa: {Riak.Connection, :start_link, ['perhap-lb1.bigsquidapp.com', 8087]}
    ]
  ]]
