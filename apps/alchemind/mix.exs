defmodule Alchemind.MixProject do
  use Mix.Project

  def project do
    [
      app: :alchemind,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "Alchemind",
      source_url: "https://github.com/bradleygolden/alchemind",
      docs: [
        main: "readme",
        extras: ["README.md", "LICENSE"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Alchemind.Application, []}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    Core library for Alchemind, providing shared functionality and utilities for AI-powered applications.
    """
  end

  defp package do
    [
      name: "alchemind",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/bradleygolden/alchemind"
      }
    ]
  end
end
