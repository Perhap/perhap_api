use Mix.Config

import_config "#{Mix.env}.exs"

config :quantum,
  global?: true

  config :reducers,
  services: :all,
  current_season: Season1, #after 9 seasons, some code will need minor changes to accomadate a 2 digit season. in bracket task.
  current_periods: Season1periods,
  seeding_date: "17 21 15 6 *",
  current_season_length: 5,
  filter_by_domain: true

config :reducers, Perhap.Scheduler,
  jobs: [
    [name: "heartbeat", schedule: "* * * * *", task: {Service.Cron, :heartbeat, []}],
    [name: "bin_audit_get", schedule: "0 */12 * * *", task: {Service.Cron, :bin_audit_get, []}], #every 12 hours
    [name: "actuals_get", schedule: "0 */4 * * *", task: {Service.Cron, :actuals_get, []}], # every 4 hours
    [name: "apa_get", schedule: "0 * * * *", task: {Service.Cron, :apa_get, []}], # every hour
    [name: "seeding", schedule: "59 11 24 7 *", task: {Mix.Tasks.Seeding, :run, []}, timezone: "America/Los_Angeles"], # this will run yearly... on 7/24 at 11:59 am This is where it needs to be updated for each new season.
    [name: "weekly_bracket", schedule: "59 11 * * 1", task: {Mix.Tasks.Bracket, :run, []}, timezone: "America/Los_Angeles"] # bracket runs each week, sunday nights at 11:59 pm only returns results if in tournament play for current season
  ]

config :reducers, :domo_creds,
  client_secret: "secret to be filled in",
  client_id: "id to be filled in",
  bin_audit_dataset: "c8a5a4c2-43af-421d-a588-f880e3d713a1",
  actuals_dataset: "bc96a70b-c7ae-4b2a-bf11-2f0871955bb8",
  apa_dataset: "a7601eb1-dfd7-41e0-a9b4-65d324ca1629",
  out_going_domain: "stats",
  bin_audit_type: "bin_audit",
  actuals_type: "actuals",
  apa_type: "challenge"



config :reducers, Season1periods,
season1preseason:
  %{:start_time => 1497633280000, #Jun 16 2017
  :end_time => 1497855599000 #Jun 18
  },
  season1week1:
    %{:start_time => 1497855600000, #Jun 19 2017 07:00:00 GMT Human time (pacfic): 6/19/2017, 12:00:00 AM
    :end_time => 1498373999000 #Jun 25 06:59:59 GMT Human time (pacfic):6/25/2017, 11:59:59 PM
    },
  season1week2:
    %{:start_time => 1498374000000, #Jun 26
    :end_time => 1498978799000 #Jul 2
    },
  season1week3:
    %{:start_time => 1498978800000, #Jul 3
    :end_time => 1499583599000 #Jul 9
    },
  season1week4:
    %{:start_time => 1499583600000, # Jul 10
    :end_time => 1500188399000 # Jul 16
    },
  season1week5:
    %{:start_time => 1500188400000, #Jul 17
    :end_time => 1500793199000 #Jul 23
    },
  tournament1week1:
    %{:start_time => 1500793200000, #Jul 24
    :end_time => 1501397999000 #Jul 30
    },
  tournament1week2:
    %{:start_time => 1501398000000, #Jul 31
    :end_time => 1502002799000 #Aug 6
    },
  tournament1week3:
    %{:start_time => 1502002800000, #Aug 7
    :end_time => 1502607599000 #Aug 13
    },
  tournament1week4:
    %{:start_time => 1502607600000, #Aug 14
    :end_time => 1503212399000 #Aug 20
    },
  tournament1week5:
    %{:start_time => 1503212400000, #Aug 21
    :end_time => 1503730799000 #Aug 26
    }
