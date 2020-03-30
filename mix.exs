defmodule PostgrexPubsub.MixProject do
  use Mix.Project

  def project do
    [
      app: :postgrex_pubsub,
      version: "0.1.0",
      elixir: "~> 1.10",
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
      {:jason, "~> 1.0"},
      {:postgrex, "~> 0.15.3"},
      {:ecto_sql, "~> 3.0"}
    ]
  end
end
