defmodule PerhapAPI.Mixfile do
  use Mix.Project

  def project do
    [apps_path: "apps",
     version: "0.0.1",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  defp deps do
    [{:dialyxir, "~> 0.5", only: [:dev], runtime: false},
     {:ex_doc, "~> 0.15.0", only: :dev, runtime: false}]
  end
end
