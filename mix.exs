defmodule ERS.MixProject do
  use Mix.Project

  def project do
    [
      app: :ers,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:potato, path: "local_deps/potato-runtime-creek/"},
      {:ecto_sql, "~> 3.9"},
      {:myxql, ">= 0.6.3"},
      {:circuits_gpio, "~> 1.0"},
      {:circuits_i2c, "~> 1.0"},
      {:circuits_spi, "~> 1.3"},
      {:plug_cowboy, "~> 2.0"},
    ]
  end
end
