defmodule API.Mixfile do
  use Mix.Project

  def project do
    [app: :api,
     version: PerhapAPI.Mixfile.version,
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
      :snappy],
      mod: {API, []}
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 1.1.2"},
      {:plug, "~> 1.3"},
      {:httpoison, "~> 0.11.1"},
      {:reducers, in_umbrella: true},
      {:json, "~> 1.0"},
      {:snappy, github: "fdmanana/snappy-erlang-nif"},
      {:exometer_core, github: "Feuerlabs/exometer_core"},
      {:setup, github: "uwiger/setup", manager: :rebar, override: true},
      {:gen_stage, "~> 0.11.0"},
      {:faker, "~> 0.7.0", only: [:dev,:test], runtime: false},
      {:meck, "~> 0.8.4", runtime: false, override: true}
    ]
  end
end
