defmodule Alchemind do
  @moduledoc """
  Alchemind provides a unified interface for interacting with various LLM providers.

  This module defines the base behaviours and types for working with different
  LLM implementations in a unified way, similar to LiteLLM or LlamaIndex.
  """

  @type role :: :system | :user | :assistant

  @type message :: %{
          required(:role) => role,
          required(:content) => String.t() | nil
        }

  @type completion_choice :: %{
          required(:index) => non_neg_integer(),
          required(:message) => message(),
          optional(:finish_reason) => String.t()
        }

  @type completion_response :: %{
          required(:id) => String.t(),
          required(:object) => String.t(),
          required(:created) => pos_integer(),
          required(:model) => String.t(),
          required(:choices) => [completion_choice()]
        }

  @type completion_error :: %{
          required(:error) => %{
            required(:message) => String.t(),
            optional(:type) => String.t(),
            optional(:code) => String.t()
          }
        }

  @type completion_result :: {:ok, completion_response()} | {:error, completion_error() | any()}

  @type stream_delta :: %{
          optional(:id) => String.t(),
          optional(:model) => String.t(),
          optional(:content) => String.t(),
          optional(:role) => role(),
          optional(:finish_reason) => String.t()
        }

  @type stream_callback :: (stream_delta() -> any())

  @doc """
  Defines the client behaviour for LLM providers.

  Each provider must implement a client that conforms to this behaviour.
  """
  @callback new(opts :: keyword()) :: {:ok, term()} | {:error, term()}

  @doc """
  Completes a conversation with the LLM provider.

  Each provider module must implement this callback to handle completion requests.
  """
  @callback complete(
              client :: term(),
              messages :: [message()],
              opts :: keyword()
            ) :: completion_result()

  @doc """
  Completes a conversation with the LLM provider, with optional streaming.

  Each provider module must implement this callback to handle streaming completion requests.
  If a callback is provided, streaming is enabled.
  """
  @callback complete(
              client :: term(),
              messages :: [message()],
              callback :: stream_callback(),
              opts :: keyword()
            ) :: completion_result()

  @doc """
  Transcribes audio to text.

  Optional callback that providers can implement to support audio transcription.
  """
  @callback transcribe(
              client :: term(),
              audio_binary :: binary(),
              opts :: keyword()
            ) :: {:ok, String.t()} | {:error, term()}

  @doc """
  Converts text to speech.

  Optional callback that providers can implement to support text-to-speech conversion.
  """
  @callback speech(
              client :: term(),
              input :: String.t(),
              opts :: keyword()
            ) :: {:ok, binary()} | {:error, term()}

  @optional_callbacks [transcribe: 3, speech: 3]

  @doc """
  Creates a new client for the specified provider.

  ## Parameters

  - `provider`: Module implementing Alchemind provider behaviour
  - `opts`: Provider-specific options (like api_key, base_url, etc.)

  ## Examples

      iex> Alchemind.new(Alchemind.OpenAI, api_key: "sk-...")
      {:ok, %Alchemind.OpenAI.Client{...}}

  ## Returns

  - `{:ok, client}` - Client for the specified provider
  - `{:error, reason}` - Error with reason
  """
  @spec new(module(), keyword()) :: {:ok, term()} | {:error, term()}
  def new(provider, opts \\ []) do
    provider.new(opts)
  end

  @doc """
  Completes a conversation using the specified client, with optional streaming.

  ## Parameters

  - `client`: Client created with new/2
  - `messages`: List of messages in the conversation
  - `callback_or_opts`: Either a callback function for streaming or options for the request
  - `opts`: Additional options for the completion request (when callback is provided)

  ## Options

  - `:model` - The model to use (required unless specified in the client)
  - `:temperature` - Controls randomness (0.0 to 2.0)
  - `:max_tokens` - Maximum number of tokens to generate

  ## Examples

  Without streaming:

      iex> {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: "sk-...")
      iex> messages = [
      ...>   %{role: :system, content: "You are a helpful assistant."},
      ...>   %{role: :user, content: "Hello, world!"}
      ...> ]
      iex> Alchemind.complete(client, messages, model: "gpt-4o", temperature: 0.7)

  With streaming:

      iex> {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: "sk-...")
      iex> messages = [
      ...>   %{role: :system, content: "You are a helpful assistant."},
      ...>   %{role: :user, content: "Hello, world!"}
      ...> ]
      iex> callback = fn delta -> IO.write(delta.content) end
      iex> Alchemind.complete(client, messages, callback, model: "gpt-4o", temperature: 0.7)

  ## Returns

  - `{:ok, response}` - Successful completion with response data
  - `{:error, reason}` - Error with reason
  """
  @spec complete(term(), [message()], stream_callback() | keyword(), keyword()) :: completion_result()
  def complete(client, messages, callback_or_opts \\ [], opts \\ [])

  def complete(%{provider: provider} = client, messages, callback, opts) when is_function(callback, 1) do
    provider.complete(client, messages, callback, opts)
  rescue
    UndefinedFunctionError ->
      {:error,
       %{
         error: %{
           message: "Streaming is not supported by the #{inspect(provider)} provider."
         }
       }}
  end

  def complete(%{provider: provider} = client, messages, opts, additional_opts) when is_list(opts) do
    merged_opts = Keyword.merge(opts, additional_opts)
    provider.complete(client, messages, merged_opts)
  end

  @doc """
  Transcribes audio to text using the specified client.

  ## Parameters

  - `client`: Client created with new/2
  - `audio_binary`: Binary audio data
  - `opts`: Options for the transcription request

  ## Options

  Options are provider-specific. For OpenAI:

  - `:model` - Transcription model to use (default: "whisper-1")
  - `:language` - Language of the audio (default: nil, auto-detect)
  - `:prompt` - Optional text to guide the model's transcription
  - `:response_format` - Format of the transcript (default: "json")
  - `:temperature` - Controls randomness (0.0 to 1.0, default: 0)

  ## Examples

      iex> {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: "sk-...")
      iex> audio_binary = File.read!("audio.mp3")
      iex> Alchemind.transcribe(client, audio_binary, language: "en")
      {:ok, "This is a transcription of the audio."}

  ## Returns

  - `{:ok, text}` - Successful transcription with text
  - `{:error, reason}` - Error with reason
  """
  @spec transcribe(term(), binary(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def transcribe(%{provider: provider} = client, audio_binary, opts \\ []) do
    provider.transcribe(client, audio_binary, opts)
  rescue
    UndefinedFunctionError ->
      {:error,
       %{
         error: %{
           message: "Transcription is not supported by the #{inspect(provider)} provider."
         }
       }}
  end

  @doc """
  Converts text to speech using the specified client.

  ## Parameters

  - `client`: Client created with new/2
  - `input`: Text to convert to speech
  - `opts`: Options for the speech request

  ## Options

  Options are provider-specific. For OpenAI:

  - `:model` - OpenAI text-to-speech model to use (default: "gpt-4o-mini-tts")
  - `:voice` - Voice to use (default: "alloy")
  - `:response_format` - Format of the audio (default: "mp3")
  - `:speed` - Speed of the generated audio (optional)

  ## Examples

      iex> {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: "sk-...")
      iex> Alchemind.speech(client, "Hello, world!", voice: "echo")
      {:ok, <<binary audio data>>}

  ## Returns

  - `{:ok, audio_binary}` - Successful speech generation with audio binary
  - `{:error, reason}` - Error with reason
  """
  @spec speech(term(), String.t(), keyword()) :: {:ok, binary()} | {:error, term()}
  def speech(%{provider: provider} = client, input, opts \\ []) do
    provider.speech(client, input, opts)
  rescue
    UndefinedFunctionError ->
      {:error,
       %{
         error: %{
           message: "Text-to-speech is not supported by the #{inspect(provider)} provider."
         }
       }}
  end
end
