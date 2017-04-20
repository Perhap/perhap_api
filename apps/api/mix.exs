defmodule API.Mixfile do
  use Mix.Project

  def project do
    [app: :api,
     version: "0.0.1",
     elixir: "~> 1.3",
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
      #      :kafka_ex,
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
      {:snappy, git: "https://github.com/fdmanana/snappy-erlang-nif"}
    ]
  end
end
