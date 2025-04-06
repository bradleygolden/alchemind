defmodule AlchemindTest do
  use ExUnit.Case, async: true

  defmodule MockProvider do
    @moduledoc false
    @behaviour Alchemind

    defmodule Client do
      @moduledoc false
      defstruct provider: MockProvider,
                api_key: nil,
                settings: nil
    end

    @impl Alchemind
    def new(opts) do
      if opts[:fail_new] do
        {:error, "Mock initialization error"}
      else
        {:ok, %Client{api_key: opts[:api_key] || "mock-key", settings: opts}}
      end
    end

    @impl Alchemind
    def complete(client, _messages, model, _opts) do
      if client.settings[:return_error] do
        {:error, %{error: %{message: "Mock error"}}}
      else
        {:ok,
         %{
           id: "mock-id",
           object: "chat.completion",
           created: System.os_time(:second),
           model: model,
           choices: [
             %{
               index: 0,
               message: %{
                 role: :assistant,
                 content: "Mock response for #{client.api_key}"
               },
               finish_reason: "stop"
             }
           ]
         }}
      end
    end
  end

  describe "new/2" do
    test "creates a client for the given provider" do
      result = Alchemind.new(MockProvider, api_key: "test-key")
      assert {:ok, client} = result
      assert client.__struct__ == MockProvider.Client
      assert client.api_key == "test-key"
    end

    test "returns error when provider fails" do
      result = Alchemind.new(MockProvider, fail_new: true)
      assert result == {:error, "Mock initialization error"}
    end
  end

  describe "complete/4" do
    test "forwards the call to the provider module" do
      {:ok, client} = Alchemind.new(MockProvider, api_key: "test-key")

      messages = [
        %{role: :system, content: "You are a helpful assistant."},
        %{role: :user, content: "Hello, world!"}
      ]

      result = Alchemind.complete(client, messages, "test-model", temperature: 0.7)
      assert {:ok, response} = result
      assert response.id == "mock-id"
      assert response.model == "test-model"
      assert length(response.choices) == 1

      assistant_message = List.first(response.choices).message
      assert assistant_message.content == "Mock response for test-key"
    end
  end
end
