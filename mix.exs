defmodule WebPushElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :web_push_elixir,
      version: "0.4.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Simple web push for Elixir",
      package: [
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/midarrlabs/web-push-elixir"}
      ],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {WebPushElixir.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jose, "~> 1.11"},
      {:jason, "~> 1.4"},
      {:httpoison, "~> 2.0"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:plug, "~> 1.14", only: :test},
      {:plug_cowboy, "~> 2.0", only: :test}
    ]
  end
end
