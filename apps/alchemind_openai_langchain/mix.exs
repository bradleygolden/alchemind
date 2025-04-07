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
      deps: deps(),
      description: description(),
      package: package(),
      name: "AlchemindOpenAILangChain",
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
      mod: {Alchemind.OpenAILangChain.Application, []}
    ]
  end

  defp local_umbrella_deps? do
    System.get_env("LOCAL_UMBRELLA_DEPS") == "true"
  end

  defp umbrella_dep(dep) do
    if local_umbrella_deps?() do
      {dep, in_umbrella: true}
    else
      {dep, git: "https://github.com/bradleygolden/alchemind.git"}
    end
  end

  defp deps do
    [
      umbrella_dep(:alchemind),
      {:langchain, "~> 0.3.2"},
      {:uuid, "~> 1.1"},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  defp description do
    """
    An Elixir package integrating OpenAI with LangChain, providing advanced language model capabilities and chains.
    """
  end

  defp package do
    [
      name: "alchemind_openai_langchain",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/bradleygolden/alchemind"
      }
    ]
  end
end
