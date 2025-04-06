defmodule AlchemindIntegration.OpenAILangChainIntegrationTest do
  use AlchemindIntegration.IntegrationCase, async: false

  setup do
    api_key = Application.get_env(:alchemind_openai_langchain, :api_key)
    default_model = Application.get_env(:alchemind_openai_langchain, :default_model)
    {:ok, %{api_key: api_key, default_model: default_model}}
  end

  describe "OpenAI LangChain client creation" do
    test "creates a new OpenAI LangChain client" do
      {:ok, client} = Alchemind.OpenAILangChain.new(api_key: "sk-test-key")

      assert %Alchemind.OpenAILangChain.Client{} = client
      assert client.llm.api_key == "sk-test-key"
      assert client.provider == Alchemind.OpenAILangChain
    end

    test "returns error when API key is missing" do
      result = Alchemind.OpenAILangChain.new()

      assert {:error, error_message} = result
      assert error_message =~ "API key not provided"
    end

    test "creates client through Alchemind facade" do
      {:ok, client} = Alchemind.new(Alchemind.OpenAILangChain, api_key: "sk-test-key")

      assert %Alchemind.OpenAILangChain.Client{} = client
      assert client.provider == Alchemind.OpenAILangChain
      assert client.llm.api_key == "sk-test-key"
    end
  end

  describe "OpenAI LangChain API integration" do
    test "connects to OpenAI API via LangChain and gets a response", %{
      api_key: api_key,
      default_model: default_model
    } do
      {:ok, client} = Alchemind.new(Alchemind.OpenAILangChain, api_key: api_key)

      messages = [
        %{role: :system, content: "You are a helpful assistant. Respond briefly."},
        %{role: :user, content: "Say hello in one word."}
      ]

      result = Alchemind.complete(client, messages, default_model)

      assert {:ok, response} = result
      assert is_binary(response.id)
      assert is_integer(response.created)
      assert response.model == default_model || response.model =~ default_model
      assert length(response.choices) > 0

      [choice] = response.choices
      assert choice.message.role == :assistant
      assert is_binary(choice.message.content)
      word_count = choice.message.content |> String.split() |> length()

      assert word_count <= 3,
             "Expected a short response (1-3 words), got: '#{choice.message.content}'"
    end

    test "can use different models", %{api_key: api_key} do
      {:ok, client} = Alchemind.new(Alchemind.OpenAILangChain, api_key: api_key)

      messages = [
        %{role: :system, content: "You are a helpful assistant."},
        %{role: :user, content: "What model are you? Respond in one sentence."}
      ]

      result = Alchemind.complete(client, messages, "gpt-4o-mini")

      assert {:ok, response} = result
      assert is_binary(response.id)
      assert response.model =~ "gpt-4o-mini"
      assert length(response.choices) > 0
    end

    test "handles temperature parameter", %{api_key: api_key, default_model: default_model} do
      {:ok, client} = Alchemind.new(Alchemind.OpenAILangChain, api_key: api_key)

      messages = [
        %{role: :system, content: "You are a creative assistant."},
        %{role: :user, content: "Give me a random fruit name. Just the name, one word."}
      ]

      result = Alchemind.complete(client, messages, default_model, temperature: 1.0)

      assert {:ok, response} = result
      assert is_binary(response.id)
      assert length(response.choices) > 0

      [choice] = response.choices
      fruit_name = choice.message.content |> String.trim()

      assert is_binary(fruit_name)
      assert String.length(fruit_name) > 0
    end

    test "limits response length with max_tokens", %{
      api_key: api_key,
      default_model: default_model
    } do
      {:ok, client} = Alchemind.new(Alchemind.OpenAILangChain, api_key: api_key)

      messages = [
        %{role: :system, content: "You are a helpful assistant."},
        %{role: :user, content: "Tell me about Elixir programming language."}
      ]

      max_tokens = 20
      result = Alchemind.complete(client, messages, default_model, max_tokens: max_tokens)

      assert {:ok, response} = result
      assert is_binary(response.id)
      assert length(response.choices) > 0

      [choice] = response.choices
      assert choice.finish_reason == "stop" || choice.finish_reason == "length"
      assert String.length(choice.message.content) < 200
    end
  end

  test "handles error when API key is invalid", %{default_model: default_model} do
    {:ok, client} = Alchemind.new(Alchemind.OpenAILangChain, api_key: "invalid_key")

    messages = [
      %{role: :user, content: "Hello"}
    ]

    result = Alchemind.complete(client, messages, default_model)

    assert {:error, error} = result
    assert is_map(error) || is_binary(error)
    
    if is_map(error) do
      assert Map.has_key?(error, "error") || Map.has_key?(error, :error)
    else
      assert error =~ "api_key" || error =~ "unauthorized" || error =~ "invalid"
    end
  end
end