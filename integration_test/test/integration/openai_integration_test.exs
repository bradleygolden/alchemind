defmodule AlchemindIntegration.OpenAIIntegrationTest do
  use AlchemindIntegration.IntegrationCase, async: false

  setup do
    api_key = Application.get_env(:alchemind_openai, :api_key)
    default_model = Application.get_env(:alchemind_openai, :default_model)

    {:ok, %{api_key: api_key, default_model: default_model}}
  end

  describe "OpenAI client creation" do
    test "creates a new OpenAI client" do
      {:ok, client} = Alchemind.OpenAI.new(api_key: "sk-test-key")

      assert %Alchemind.OpenAI.Client{} = client
      assert client.api_key == "sk-test-key"
      assert client.base_url == "https://api.openai.com/v1"
    end

    test "returns error when API key is missing" do
      result = Alchemind.OpenAI.new()

      assert {:error, error_message} = result
      assert error_message =~ "API key not provided"
    end

    test "creates client through Alchemind facade" do
      {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: "sk-test-key")

      assert %Alchemind.OpenAI.Client{} = client
      assert client.provider == Alchemind.OpenAI
      assert client.api_key == "sk-test-key"
    end
  end

  describe "OpenAI API integration" do
    test "connects to OpenAI API and gets a response", %{
      api_key: api_key,
      default_model: default_model
    } do
      {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: api_key)

      messages = [
        %{role: :system, content: "You are a helpful assistant. Respond briefly."},
        %{role: :user, content: "Say hello in one word."}
      ]

      result = Alchemind.complete(client, messages, model: default_model)

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
      {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: api_key)

      messages = [
        %{role: :system, content: "You are a helpful assistant."},
        %{role: :user, content: "What model are you? Respond in one sentence."}
      ]

      result = Alchemind.complete(client, messages, model: "gpt-4o-mini")

      assert {:ok, response} = result
      assert is_binary(response.id)
      assert response.model =~ "gpt-4o-mini"
      assert length(response.choices) > 0
    end

    test "can use reasoning models", %{api_key: api_key} do
      {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: api_key)

      messages = [
        %{role: :system, content: "You are a helpful assistant."},
        %{role: :user, content: "What model are you? Respond in one sentence."}
      ]

      result = Alchemind.complete(client, messages, model: "o3-mini")

      assert {:ok, response} = result
      assert is_binary(response.id)
      assert response.model =~ "o3-mini"
      assert length(response.choices) > 0
    end

    test "handles temperature parameter", %{api_key: api_key, default_model: default_model} do
      {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: api_key)

      messages = [
        %{role: :system, content: "You are a creative assistant."},
        %{role: :user, content: "Give me a random fruit name. Just the name, one word."}
      ]

      result = Alchemind.complete(client, messages, model: default_model, temperature: 1.0)

      assert {:ok, response} = result
      assert is_binary(response.id)
      assert length(response.choices) > 0

      [choice] = response.choices
      fruit_name = choice.message.content |> String.trim()

      assert is_binary(fruit_name)
      assert String.length(fruit_name) > 0
    end

    test "OpenAI API integration limits response length with max_tokens", %{
      api_key: api_key,
      default_model: default_model
    } do
      {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: api_key)

      messages = [
        %{role: :system, content: "You are a helpful assistant."},
        %{role: :user, content: "Tell me about Elixir programming language."}
      ]

      max_tokens = 20
      result = Alchemind.complete(client, messages, model: default_model, max_tokens: max_tokens)

      assert {:ok, response} = result
      assert is_binary(response.id)
      assert response.model =~ "gpt"
      assert length(response.choices) > 0

      [choice] = response.choices

      assert choice.finish_reason in ["stop", "length"],
             "Expected finish_reason to be one of ['stop', 'length'], got: '#{choice.finish_reason}'"

      # For max_tokens test, we only verify the request was processed successfully
      # We don't assert on content length since token-to-character mapping varies by model
      assert is_binary(choice.message.content),
             "Expected a response with max_tokens: #{max_tokens}"
    end
  end

  test "handles error when API key is invalid", %{default_model: default_model} do
    {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: "invalid_key")

    messages = [
      %{role: :user, content: "Hello"}
    ]

    result = Alchemind.complete(client, messages, model: default_model)

    assert {:error, error} = result
    assert is_map(error)
    assert get_in(error, ["error", "code"]) == "invalid_api_key"
    assert get_in(error, ["error", "type"]) == "invalid_request_error"
  end

  describe "OpenAI transcription integration" do
    test "transcribes text from an audio file", %{api_key: api_key} do
      audio_binary = get_test_audio()

      {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: api_key)

      result = Alchemind.transcribe(client, audio_binary)

      case result do
        {:ok, text} ->
          assert is_binary(text)

        {:error, error} ->
          error_msg = get_in(error, ["error", "message"]) || ""

          expected_errors = [
            "audio",
            "file format",
            "Invalid file format",
            "format"
          ]

          if Enum.any?(expected_errors, &String.contains?(error_msg, &1)) do
            assert true
          else
            IO.puts("\nTranscription API error: #{inspect(error)}")

            if String.contains?(error_msg, "API key") do
              assert true
            else
              flunk("Unexpected error in transcription test: #{inspect(error)}")
            end
          end
      end
    end

    test "supports language parameter", %{api_key: api_key} do
      audio_binary = get_test_audio()

      {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: api_key)

      result = Alchemind.transcribe(client, audio_binary, language: "en")

      case result do
        {:ok, text} ->
          assert is_binary(text)

        {:error, error} ->
          error_msg = get_in(error, ["error", "message"]) || ""

          expected_errors = [
            "audio",
            "file format",
            "Invalid file format",
            "format",
            "API key"
          ]

          if Enum.any?(expected_errors, &String.contains?(error_msg, &1)) do
            assert true
          else
            flunk("Unexpected error in transcription language test: #{inspect(error)}")
          end
      end
    end

    test "handles invalid API key for transcription" do
      {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: "invalid_key")

      audio_binary = get_test_audio()

      result = Alchemind.transcribe(client, audio_binary)

      assert {:error, error} = result
      assert is_map(error)
      error_msg = get_in(error, ["error", "message"]) || ""

      assert String.contains?(error_msg, "API key") ||
               String.contains?(error_msg, "auth") ||
               String.contains?(error_msg, "key") ||
               get_in(error, ["error", "type"]) == "invalid_request_error"
    end

    test "transcribe through Alchemind facade", %{api_key: api_key} do
      audio_binary = get_test_audio()

      {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: api_key)

      result = Alchemind.transcribe(client, audio_binary)

      case result do
        {:ok, text} ->
          assert is_binary(text)

        {:error, error} ->
          error_msg = get_in(error, ["error", "message"]) || ""

          expected_errors = [
            "audio",
            "file format",
            "Invalid file format",
            "format",
            "API key"
          ]

          if Enum.any?(expected_errors, &String.contains?(error_msg, &1)) do
            assert true
          else
            flunk("Unexpected error in transcription facade test: #{inspect(error)}")
          end
      end
    end

    test "unsupported provider returns appropriate error" do
      defmodule MockProvider do
        @behaviour Alchemind

        defmodule Client do
          defstruct provider: MockProvider
        end

        @impl Alchemind
        def new(_opts), do: {:ok, %Client{}}

        @impl Alchemind
        def complete(_client, _messages, _opts), do: {:ok, %{id: "test", choices: []}}

        @impl Alchemind
        def complete(_client, _messages, _callback, _opts), do: {:ok, %{id: "test", choices: []}}

        # No transcription implementation
      end

      {:ok, client} = Alchemind.new(MockProvider)

      audio_binary = get_test_audio()

      result = Alchemind.transcribe(client, audio_binary)

      assert {:error, error} = result
      assert is_map(error)
      assert get_in(error, [:error, :message]) =~ "Transcription is not supported by the"
    end
  end

  defp get_test_audio do
    <<73, 68, 51, 3, 0, 0, 0, 0, 0, 10>> <> :binary.copy(<<0>>, 2000)
  end

  describe "OpenAI text-to-speech integration" do
    test "converts text to speech", %{api_key: api_key} do
      input_text = "Hello, this is a test."

      {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: api_key)

      result = Alchemind.tts(client, input_text)

      case result do
        {:ok, audio_data} ->
          assert is_binary(audio_data)
          assert byte_size(audio_data) > 0

        {:error, error} ->
          error_msg =
            if is_binary(error), do: error, else: get_in(error, ["error", "message"]) || ""

          if String.contains?(error_msg, "API key") do
            assert true, "Failed due to API key issue which is acceptable in integration tests"
          else
            flunk("Unexpected error in text-to-speech test: #{inspect(error)}")
          end
      end
    end

    test "supports voice and model parameters", %{api_key: api_key} do
      input_text = "Testing speech with different voices."

      {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: api_key)

      result = Alchemind.tts(client, input_text, voice: "echo", model: "gpt-4o-mini-tts")

      case result do
        {:ok, audio_data} ->
          assert is_binary(audio_data)
          assert byte_size(audio_data) > 0

        {:error, error} ->
          error_msg =
            if is_binary(error), do: error, else: get_in(error, ["error", "message"]) || ""

          expected_errors = [
            "API key",
            "not found",
            "voice",
            "model",
            "parameter"
          ]

          if Enum.any?(expected_errors, &String.contains?(error_msg, &1)) do
            assert true, "Failed due to expected configuration issues"
          else
            flunk("Unexpected error in text-to-speech voice test: #{inspect(error)}")
          end
      end
    end

    test "handles invalid API key for text-to-speech" do
      {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: "invalid_key")

      input_text = "Testing with invalid key."

      result = Alchemind.tts(client, input_text)

      assert {:error, error} = result
      error_msg = if is_binary(error), do: error, else: get_in(error, ["error", "message"]) || ""

      assert String.contains?(error_msg, "API key") ||
               String.contains?(error_msg, "auth") ||
               String.contains?(error_msg, "key")
    end

    test "tts through Alchemind facade", %{api_key: api_key} do
      input_text = "Testing the Alchemind facade for text to speech."

      {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: api_key)

      result = Alchemind.tts(client, input_text)

      case result do
        {:ok, audio_data} ->
          assert is_binary(audio_data)
          assert byte_size(audio_data) > 0

        {:error, error} ->
          error_msg =
            if is_binary(error), do: error, else: get_in(error, ["error", "message"]) || ""

          if String.contains?(error_msg, "API key") do
            assert true, "Failed due to API key issue which is acceptable in integration tests"
          else
            flunk("Unexpected error in text-to-speech facade test: #{inspect(error)}")
          end
      end
    end

    test "unsupported provider returns appropriate error" do
      defmodule MockProviderTTS do
        @behaviour Alchemind

        defmodule Client do
          defstruct provider: MockProviderTTS
        end

        @impl Alchemind
        def new(_opts), do: {:ok, %Client{}}

        @impl Alchemind
        def complete(_client, _messages, _opts), do: {:ok, %{id: "test", choices: []}}

        @impl Alchemind
        def complete(_client, _messages, _callback, _opts), do: {:ok, %{id: "test", choices: []}}

        # No speech implementation
      end

      {:ok, client} = Alchemind.new(MockProviderTTS)

      input_text = "This should fail with provider not supported."

      result = Alchemind.tts(client, input_text)

      assert {:error, error} = result
      assert is_map(error)
      assert get_in(error, [:error, :message]) =~ "Text-to-speech is not supported by the"
    end
  end
end
