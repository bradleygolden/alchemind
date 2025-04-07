defmodule AlchemindTest do
  use ExUnit.Case, async: true

  defmodule MockProvider do
    @moduledoc false
    @behaviour Alchemind

    defmodule Client do
      @moduledoc false
      defstruct provider: MockProvider,
                api_key: nil,
                settings: nil,
                model: nil
    end

    @impl Alchemind
    def new(opts) do
      if opts[:fail_new] do
        {:error, "Mock initialization error"}
      else
        {:ok,
         %Client{
           api_key: opts[:api_key] || "mock-key",
           settings: opts,
           model: opts[:model]
         }}
      end
    end

    @impl Alchemind
    def complete(%Client{} = client, _messages, opts) do
      model = opts[:model] || client.model || "default-model"

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

    @impl Alchemind
    def complete(%Client{} = client, _messages, callback, opts) when is_function(callback, 1) do
      model = opts[:model] || client.model || "default-model"

      if client.settings[:return_error] do
        {:error, %{error: %{message: "Mock error"}}}
      else
        callback.(%{content: "Mock "})
        callback.(%{content: "streaming "})
        callback.(%{content: "response "})
        callback.(%{content: "for "})
        callback.(%{content: client.api_key})

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
                 content: "Mock streaming response for #{client.api_key}"
               },
               finish_reason: "stop"
             }
           ]
         }}
      end
    end

    @impl Alchemind
    def transcribe(%Client{} = client, _audio_binary, opts) do
      if client.settings[:transcription_error] do
        {:error, "Mock transcription error"}
      else
        language = opts[:language] || "en"
        {:ok, "Mock transcription in #{language} for #{client.api_key}"}
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

  describe "complete/3" do
    test "forwards the call to the provider module" do
      {:ok, client} = Alchemind.new(MockProvider, api_key: "test-key")

      messages = [
        %{role: :system, content: "You are a helpful assistant."},
        %{role: :user, content: "Hello, world!"}
      ]

      result = Alchemind.complete(client, messages, model: "test-model", temperature: 0.7)
      assert {:ok, response} = result
      assert response.id == "mock-id"
      assert response.model == "test-model"
      assert length(response.choices) == 1

      assistant_message = List.first(response.choices).message
      assert assistant_message.content == "Mock response for test-key"
    end
  end

  describe "complete/4" do
    test "handles streaming with callback" do
      {:ok, client} = Alchemind.new(MockProvider, api_key: "test-key")

      messages = [
        %{role: :system, content: "You are a helpful assistant."},
        %{role: :user, content: "Hello, world!"}
      ]

      test_pid = self()

      callback = fn delta ->
        if delta[:content] do
          send(test_pid, {:chunk, delta[:content]})
        end
      end

      result = Alchemind.complete(client, messages, callback, model: "test-model", temperature: 0.7)
      assert {:ok, response} = result
      assert response.id == "mock-id"
      assert response.model == "test-model"
      assert length(response.choices) == 1

      assert_receive {:chunk, "Mock "}, 100
      assert_receive {:chunk, "streaming "}, 100
      assert_receive {:chunk, "response "}, 100
      assert_receive {:chunk, "for "}, 100
      assert_receive {:chunk, "test-key"}, 100

      assistant_message = List.first(response.choices).message
      assert assistant_message.content == "Mock streaming response for test-key"
    end
  end

  describe "transcribe/3" do
    test "forwards the call to the provider module" do
      {:ok, client} = Alchemind.new(MockProvider, api_key: "test-key")

      audio_binary = <<0, 1, 2, 3, 4, 5>>

      result = Alchemind.transcribe(client, audio_binary, language: "es")
      assert {:ok, text} = result
      assert text == "Mock transcription in es for test-key"
    end

    test "handles provider errors" do
      {:ok, client} = Alchemind.new(MockProvider, transcription_error: true)

      audio_binary = <<0, 1, 2, 3, 4, 5>>

      result = Alchemind.transcribe(client, audio_binary)
      assert {:error, "Mock transcription error"} = result
    end

    defmodule ProviderWithoutTranscription do
      @moduledoc false
      @behaviour Alchemind

      defmodule Client do
        @moduledoc false
        defstruct provider: ProviderWithoutTranscription
      end

      @impl Alchemind
      def new(_opts) do
        {:ok, %Client{}}
      end

      @impl Alchemind
      def complete(%Client{}, _messages, _opts) do
        {:ok, %{id: "test", object: "chat.completion", created: 0, model: "test", choices: []}}
      end

      @impl Alchemind
      def complete(%Client{}, _messages, _callback, _opts) do
        {:ok, %{id: "test", object: "chat.completion", created: 0, model: "test", choices: []}}
      end

      # No transcription implementation
    end

    test "handles providers without transcription support" do
      {:ok, client} = Alchemind.new(ProviderWithoutTranscription)

      audio_binary = <<0, 1, 2, 3, 4, 5>>

      result = Alchemind.transcribe(client, audio_binary)
      assert {:error, %{error: %{message: message}}} = result
      assert message =~ "Transcription is not supported by the"
    end
  end
end
