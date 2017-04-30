defmodule API.Mixfile do
  use Mix.Project

  def project do
    [app: :api,
     version: "0.0.1",
     elixir: "~> 1.4",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [
      :logger,
      :cowboy,
      :exometer_core,
      # :kafka_ex,
      :snappy],
      mod: {API, []}
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 1.0"},
      {:plug, "~> 1.3"},
      {:httpoison, "~> 0.11.1"},
      {:db, in_umbrella: true},
      {:poison, "~> 3.1"},
      {:kafka_ex, "~> 0.6.5"},
      {:snappy, github: "fdmanana/snappy-erlang-nif"},
      {:exometer_core, github: "Feuerlabs/exometer_core"},
      {:setup, github: "uwiger/setup", manager: :rebar, override: true},
      #{:exometer_core, "~> 1.4"},
      {:faker, "~> 0.7.0", only: [:dev,:test], runtime: false},
      {:meck, "~> 0.8.4", runtime: false, override: true}
    ]
  end
end
