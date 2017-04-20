defmodule DB.Mixfile do
  use Mix.Project

  def project do
    [app: :db,
     version: "0.0.1",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:tzdata, "~> 0.5.12"},
      {:geocalc, "~> 0.5.4"},
      {:riak, "~> 1.1"},
      {:timex, "~> 3.1"},
      {:uuid, github: "okeuday/uuid"}
    ]
  end
end
