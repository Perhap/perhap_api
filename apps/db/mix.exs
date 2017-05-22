defmodule DB.Mixfile do
  use Mix.Project

  def project do
    [app: :db,
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
    [
      applications: [
        :logger,
        :tzdata,
        :riak],
        #:phoenix_pubsub],
        # mod: {DB, []}
    ]
  end

  defp deps do
    [
      {:tzdata, "~> 0.5.12"},
      {:geocalc, "~> 0.5.4"},
      {:riak, "~> 1.1.2"},
      {:timex, "~> 3.1"},
      # {:phoenix_pubsub, "~> 1.0"},
      {:uuid, github: "okeuday/uuid"}
    ]
  end
end
