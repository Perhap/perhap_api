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
      # :kafka_ex,
      :logger],
      mod: {Reducers, []}
    ]
  end

  defp deps do
    [
      {:db, in_umbrella: true},
      {:poison, "~> 3.1"},
      {:kafka_ex, "~> 0.6.5"},
      {:quantum, ">= 1.9.2"},
      {:httpoison, "~> 0.11.1"}
    ]
  end
end
