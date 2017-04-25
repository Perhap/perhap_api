use Mix.Config

config :db,
  url: 'perhap-test-load-1.bigsquid.com',
  unit_separator: "_"

config :pooler,
  [pools: [
    [name: :riaklocal1,
     group: :riak,
     max_count: 5,
     init_count: 2,
     start_mfa: {Riak.Connection, :start_link, ['127.0.0.1', 8087]}],
    [name: :riaklocal2,
     group: :riak,
     max_count: 3,
     init_count: 1,
     start_mfa: {Riak.Connection, :start_link, ['127.0.0.1', 8087]}]
  ]]
