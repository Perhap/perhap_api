use Mix.Config

import_config "#{Mix.env}.exs"

config :quantum,
global?: true

config :quantum, :reducers,
  cron: [
    # Every hour
    "*/60 * * * *": {Service.Cron, :bin_audit_event},
    "*/60 * * * *": {Service.Cron, :actuals_event},
    "* * * * *": {Service.Cron, :test}
  ]

config :reducers,
  # services: :all,
  services: [Service.Stats, Service.PerhapStats, Service.PerhapLog, Service.Challenge],
  current_season: Season1,
  current_periods: Season1periods

config :reducers, :domo_creds,
  client_secret: "secret to be filled in",
  client_id: "id to be filled in",
  bin_audit_dataset: "39367e6a-fb49-4e98-8547-2645eb58140d",
  actuals_dataset: "cd0192e1-078f-49b4-9116-6a7f36c4b6e2",
  out_going_domain: "stats",
  bin_audit_type: "bin_audit",
  actuals_type: "actuals"

config :reducers, Season1periods,
  season1preseason:
    %{:start_time =>  1494288000000, # May 9
    :end_time =>  1495436399000 # May 21, 11:59 pm
    },
  season1week1:
    %{:start_time => 1495436400000, #Human time (GMT): Mon, 22 May 2017 07:00:00 GMT Human time (pacfic): 5/22/2017, 12:00:00 AM
    :end_time =>  1495954799000 # Human time (GMT): Sun, 28 May 2017 06:59:59 GMT Human time (pacfic): 5/28/2017, 11:59:59 AM
    },
  season1week2:
    %{:start_time => 1496041200000, #May 29
    :end_time => 1496559599000 #Jun 4
    },
  season1week3:
    %{:start_time => 1496646000000, #Jun 5
    :end_time => 1497164399000 #Jun 11
    },
  season1week4:
    %{:start_time => 1497250800000, #Jun 12
    :end_time => 1497769199000 #Jun 18
    },
  season1week5:
    %{:start_time => 1497855600000, #Jun 19
    :end_time => 1498373999000 #Jun 24
    },
  tournament1week1:
    %{:start_time => 1498460400000, #Jun 26
    :end_time => 1498978799000 #Jul 2
    },
  tournament1week2:
    %{:start_time => 1499065200000, #Jul 3
    :end_time => 1499583599000 #Jul 9
    },
  tournament1week3:
    %{:start_time => 1499670000000, # Jul 10
    :end_time => 1500188399000 # Jul 16
    },
  tournament1week4:
    %{:start_time => 1500274800000, #Jul 17
    :end_time => 1500793199000 #Jul 23
    },
  tournament1week5:
    %{:start_time => 1500879600000, #Jul 24
    :end_time => 1501397999000 #Jul 30
    }
