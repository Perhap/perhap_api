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
      :gproc,
      :observer_cli],
      mod: {API, []}
    ]
  end

  defp deps do
    [
      {:cowboy, github: "ninenines/cowboy"},
      {:gproc, "~> 0.6.1"},
      {:ranch, github: "ninenines/ranch", ref: "1.4.0", override: true},
      {:gun, github: "ninenines/gun", ref: "1.0.0-pre.3", runtime: false},
      {:reducers, in_umbrella: true},
      {:json, "~> 1.0"},
      {:exometer_core, github: "Feuerlabs/exometer_core"},
      {:setup, github: "uwiger/setup", manager: :rebar, override: true},
      {:gen_stage, "~> 0.12.0"},
      {:observer_cli, "~> 1.1.0"},
      {:meck, "~> 0.8.4", runtime: false, override: true}
    ]
  end
end
