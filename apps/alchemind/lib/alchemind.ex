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
              model :: String.t(),
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
              model :: String.t(),
              callback :: stream_callback() | nil,
              opts :: keyword()
            ) :: completion_result()

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
  - `model`: The model to use for completion
  - `callback_or_opts`: Either a callback function for streaming or options for the request
  - `opts`: Additional options for the completion request (when callback is provided)

  ## Examples

  Without streaming:

      iex> {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: "sk-...")
      iex> messages = [
      ...>   %{role: :system, content: "You are a helpful assistant."},
      ...>   %{role: :user, content: "Hello, world!"}
      ...> ]
      iex> Alchemind.complete(client, messages, "gpt-4o", temperature: 0.7)

  With streaming:

      iex> {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: "sk-...")
      iex> messages = [
      ...>   %{role: :system, content: "You are a helpful assistant."},
      ...>   %{role: :user, content: "Hello, world!"}
      ...> ]
      iex> callback = fn delta -> IO.write(delta.content) end
      iex> Alchemind.complete(client, messages, "gpt-4o", callback, temperature: 0.7)

  ## Returns

  - `{:ok, response}` - Successful completion with response data
  - `{:error, reason}` - Error with reason
  """
  @spec complete(term(), [message()], String.t(), stream_callback() | keyword(), keyword()) :: completion_result()
  def complete(client, messages, model, callback_or_opts \\ [], opts \\ [])

  def complete(%{provider: provider} = client, messages, model, callback, opts) when is_function(callback, 1) do
    if function_exported?(provider, :complete, 5) do
      provider.complete(client, messages, model, callback, opts)
    else
      {:error,
       %{
         error: %{
           message: "Streaming is not supported by the #{inspect(provider)} provider."
         }
       }}
    end
  end

  def complete(%{provider: provider} = client, messages, model, opts, _ignored_opts) when is_list(opts) do
    if function_exported?(provider, :complete, 5) do
      provider.complete(client, messages, model, nil, opts)
    else
      provider.complete(client, messages, model, opts)
    end
  end
end
