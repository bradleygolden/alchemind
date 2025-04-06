defmodule Alchemind.OpenAILangChainTest do
  use ExUnit.Case

  alias Alchemind.OpenAILangChain

  describe "new/1" do
    test "returns error when api_key is not provided" do
      assert {:error, _} = OpenAILangChain.new()
      assert {:error, _} = OpenAILangChain.new([])
    end

    test "creates a client with api_key" do
      assert {:ok, client} = OpenAILangChain.new(api_key: "test-api-key")
      assert client.provider == OpenAILangChain
      assert %LangChain.ChatModels.ChatOpenAI{} = client.llm
      assert client.llm.api_key == "test-api-key"
      assert client.llm.model == "gpt-3.5-turbo"
    end

    test "creates a client with custom options" do
      opts = [
        api_key: "test-api-key",
        base_url: "https://custom-api.com",
        model: "gpt-4",
        temperature: 0.5
      ]

      assert {:ok, client} = OpenAILangChain.new(opts)
      assert client.llm.api_key == "test-api-key"
      assert client.llm.endpoint == "https://custom-api.com"
      assert client.llm.model == "gpt-4"
      assert client.llm.temperature == 0.5
    end
  end

  describe "complete/4" do
    test "calls the LangChain LLMChain with the proper parameters", %{} do
    end
  end
end
