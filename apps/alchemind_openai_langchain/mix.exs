defmodule AlchemindOpenaiLangchain.MixProject do
  use Mix.Project

  def project do
    [
      app: :alchemind_openai_langchain,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Alchemind.OpenAILangChain.Application, []}
    ]
  end

  defp deps do
    [
      {:alchemind, in_umbrella: true},
      {:langchain, "~> 0.3.2"},
      {:uuid, "~> 1.1"}
    ]
  end
end
