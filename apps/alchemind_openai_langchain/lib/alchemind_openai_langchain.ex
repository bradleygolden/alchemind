defmodule Alchemind.OpenAILangChain do
  @moduledoc """
  OpenAI provider implementation for the Alchemind LLM interface using LangChain.

  This module implements the Alchemind behaviour for interacting with OpenAI's API
  through Elixir's LangChain library instead of using Req directly.
  """

  @behaviour Alchemind

  alias LangChain.Message
  alias LangChain.MessageDelta
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI

  defmodule Client do
    @moduledoc """
    Client struct for the OpenAI LangChain provider.
    """

    @type t :: %__MODULE__{
            provider: module(),
            llm: struct(),
            model: String.t() | nil
          }

    defstruct provider: Alchemind.OpenAILangChain,
              llm: nil,
              model: nil
  end

  @doc """
  Creates a new OpenAI LangChain client.

  ## Options

  - `:api_key` - OpenAI API key (required)
  - `:base_url` - API base URL (optional)
  - `:temperature` - Controls randomness (0.0 to 2.0)
  - `:model` - OpenAI model to use (default: gpt-3.5-turbo)

  ## Examples

      iex> Alchemind.OpenAILangChain.new(api_key: "sk-...")
      {:ok, %Alchemind.OpenAILangChain.Client{...}}

  ## Returns

  - `{:ok, client}` - OpenAI LangChain client
  - `{:error, reason}` - Error with reason
  """
  @impl Alchemind
  @spec new(keyword()) :: {:ok, Client.t()} | {:error, String.t()}
  def new(opts \\ []) do
    api_key = opts[:api_key]

    if api_key == nil do
      {:error, "OpenAI API key not provided. Please provide an :api_key option."}
    else
      chat_model_opts = %{
        api_key: api_key,
        model: opts[:model] || "gpt-3.5-turbo"
      }

      chat_model_opts =
        if opts[:base_url],
          do: Map.put(chat_model_opts, :endpoint, opts[:base_url]),
          else: chat_model_opts

      chat_model_opts =
        if opts[:temperature],
          do: Map.put(chat_model_opts, :temperature, opts[:temperature]),
          else: chat_model_opts

      llm = ChatOpenAI.new!(chat_model_opts)

      client = %Client{
        llm: llm,
        model: opts[:model]
      }

      {:ok, client}
    end
  end

  @doc """
  Completes a conversation using OpenAI's API via LangChain, with optional streaming.

  ## Parameters

  - `client`: OpenAI LangChain client created with new/1
  - `messages`: List of messages in the conversation
  - `callback_or_opts`: Callback function for streaming or options keyword list
  - `opts`: Additional options for the completion request (when callback is provided)

  ## Options

  - `:model` - OpenAI model to use (required unless specified in client)
  - `:temperature` - Controls randomness (0.0 to 2.0)
  - `:max_tokens` - Maximum number of tokens to generate

  ## Example

  Without streaming:

      iex> {:ok, client} = Alchemind.OpenAILangChain.new(api_key: "sk-...")
      iex> messages = [
      ...>   %{role: :system, content: "You are a helpful assistant."},
      ...>   %{role: :user, content: "Hello, world!"}
      ...> ]
      iex> Alchemind.OpenAILangChain.complete(client, messages, model: "gpt-4o", temperature: 0.7)

  With streaming:

      iex> {:ok, client} = Alchemind.OpenAILangChain.new(api_key: "sk-...")
      iex> messages = [
      ...>   %{role: :system, content: "You are a helpful assistant."},
      ...>   %{role: :user, content: "Hello, world!"}
      ...> ]
      iex> callback = fn delta -> IO.write(delta.content) end
      iex> Alchemind.OpenAILangChain.complete(client, messages, callback, model: "gpt-4o", temperature: 0.7)
  """
  @impl Alchemind
  @spec complete(
          Client.t(),
          [Alchemind.message()],
          Alchemind.stream_callback() | keyword(),
          keyword()
        ) ::
          Alchemind.completion_result()
  def complete(client, messages, callback_or_opts \\ [], opts \\ [])

  def complete(%Client{} = client, messages, callback, opts)
      when is_function(callback, 1) do
    model = opts[:model] || client.model || client.llm.model
    do_complete(client, messages, model, callback, opts)
  end

  def complete(%Client{} = client, messages, opts, additional_opts) when is_list(opts) do
    merged_opts = Keyword.merge(opts, additional_opts)
    model = merged_opts[:model] || client.model || client.llm.model

    if model do
      do_complete(client, messages, model, nil, merged_opts)
    else
      {:error,
       %{error: %{message: "No model specified. Provide a model via the client or as an option."}}}
    end
  end

  defp do_complete(%Client{} = client, messages, model, callback, opts) do
    langchain_messages = convert_to_langchain_messages(messages)

    is_streaming = not is_nil(callback)
    stream_opts = if is_streaming, do: [{:stream, true}], else: []
    chat_model = configure_chat_model(client.llm, model, stream_opts ++ opts)

    chain =
      LLMChain.new!(%{llm: chat_model})
      |> LLMChain.add_messages(langchain_messages)

    chain =
      if is_streaming do
        handler = %{
          on_llm_new_delta: fn _model, %MessageDelta{} = delta ->
            if delta.content do
              callback.(%{content: delta.content})
            end
          end,
          on_message_processed: fn _chain, %Message{} = _message ->
            nil
          end
        }

        LLMChain.add_callback(chain, handler)
      else
        chain
      end

    try do
      case LLMChain.run(chain) do
        {:ok, updated_chain} ->
          response = updated_chain.last_message

          {:ok,
           %{
             id: UUID.uuid4(),
             object: "chat.completion",
             created: DateTime.to_unix(DateTime.utc_now()),
             model: chat_model.model,
             choices: [
               %{
                 index: 0,
                 message: %{
                   role: :assistant,
                   content: response.content
                 },
                 finish_reason: if(opts[:max_tokens], do: "length", else: "stop")
               }
             ]
           }}

        {:error, %LLMChain{}, %LangChain.LangChainError{} = error} ->
          {:error, %{error: %{message: error.message}}}
      end
    rescue
      e in _ ->
        message = Exception.message(e)
        {:error, %{error: %{message: message}}}
    catch
      type, value ->
        {:error, %{error: %{message: "Error: #{inspect(type)}, #{inspect(value)}"}}}
    end
  end

  defp convert_to_langchain_messages(messages) do
    Enum.map(messages, fn message ->
      case message.role do
        :system -> Message.new_system!(message.content)
        :user -> Message.new_user!(message.content)
        :assistant -> Message.new_assistant!(message.content)
      end
    end)
  end

  defp configure_chat_model(llm, model, opts) do
    chat_model =
      if model != llm.model do
        %{llm | model: model}
      else
        llm
      end

    chat_model =
      if opts[:temperature] do
        %{chat_model | temperature: opts[:temperature]}
      else
        chat_model
      end

    chat_model =
      if opts[:max_tokens] do
        %{chat_model | max_tokens: opts[:max_tokens]}
      else
        chat_model
      end

    chat_model =
      if Keyword.has_key?(opts, :stream) do
        %{chat_model | stream: opts[:stream]}
      else
        chat_model
      end

    chat_model
  end
end
