defmodule SlackSampleBot.Mixfile do
  use Mix.Project

  def project do
    [
      app: :slack_sample_bot,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [mod: {SlackSampleBot, []}, extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [{:cowboy, "~> 1.1.2"},
     {:httpoison, "~> 0.13"},
     {:plug, "~> 1.4.0"},
     {:poison, "~> 2.0"}
    ]
  end
end
