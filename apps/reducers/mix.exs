defmodule Reducer.Mixfile do
  use Mix.Project

  def project do
    [app: :reducers,
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
      :quantum,
      :timex,
      :logger],
      mod: {Reducers, []}
    ]
  end

  defp deps do
    [
      {:db, in_umbrella: true},
      {:poison, "~> 3.1"},
      {:quantum, github: "c-rack/quantum-elixir"},
      {:httpoison, "~> 0.11.1"},
      {:csv, "~> 1.4.2"},
      {:poolboy, github: "devinus/poolboy"}
    ]
  end
end
