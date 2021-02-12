defmodule PostgrexPubsub.MixProject do
  use Mix.Project

  def project do
    [
      app: :postgrex_pubsub,
      name: "Postgrex PubSub",
      description: "A helper for creating and listening to pubsub events from postgres",
      version: "0.2.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      source_url:   "https://github.com/bechurch/postgrex_pubsub",
      homepage_url: "https://github.com/bechurch/postgrex_pubsub",

      package: [
        maintainers: ["Ben Church"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/bechurch/postgrex_pubsub"}
      ],
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:jason, "~> 1.0"},
      {:postgrex, "~> 0.15.3"},
      {:ecto_sql, "~> 3.0"}
    ]
  end
end
