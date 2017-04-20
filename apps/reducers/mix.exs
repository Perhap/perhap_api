defmodule Reducer.Mixfile do
  use Mix.Project

  def project do
    [app: :reducers,
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
    [applications: [:logger]]
  end

  defp deps do
    []
  end
end
