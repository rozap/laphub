defmodule LapBasestation.MixProject do
  use Mix.Project

  def project do
    [
      app: :lap_basestation,
      version: "0.1.0",
      elixir: "~> 1.13",
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
      {:circuits_uart, "~> 1.3"},
      {:phoenix_client, "~> 0.11.1"},
      {:jason, "~> 1.0"},
      {:nimble_csv, "~> 1.2"}
    ]
  end
end
