defmodule GatedDag.MixProject do
  use Mix.Project

  def project do
    [
      app: :gated_dag,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      #{:mutable_graph, git: "git@gitlab.soft.vub.ac.be:cdetroye/libmutablegraph.git", branch: "master"}
      {:mutable_graph, path: "../mutable_graph"}
    ]
  end
end
