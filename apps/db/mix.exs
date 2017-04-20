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

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:tzdata, "~> 0.5.12"},
      {:geocalc, "~> 0.5.4"},
      {:riak, "~> 1.1"},
      {:timex, "~> 3.1"},
      {:uuid, "~> 1.1"}
    ]
  end
end
