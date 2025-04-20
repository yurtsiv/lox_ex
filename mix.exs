defmodule Lox.MixProject do
  use Mix.Project

  def project do
    [
      app: :lox,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_paths: ["lib"]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Lox, []}
    ]
  end

  defp deps do
    []
  end
end
