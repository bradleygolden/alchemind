defmodule Alchemind.OpenAILangChain do
  @moduledoc """
  OpenAI provider implementation for the Alchemind LLM interface using LangChain.

  This module implements the Alchemind behaviour for interacting with OpenAI's API
  through Elixir's LangChain library instead of using Req directly.
  """

  @behaviour Alchemind

  defmodule Client do
    @moduledoc """
    Client struct for the OpenAI LangChain provider.
    """

    @type t :: %__MODULE__{
            provider: module(),
            llm: struct()
          }

    defstruct provider: Alchemind.OpenAILangChain,
              llm: nil
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

      llm = LangChain.ChatModels.ChatOpenAI.new!(chat_model_opts)

      client = %Client{
        llm: llm
      }

      {:ok, client}
    end
  end

  @doc """
  Completes a conversation using OpenAI's API via LangChain.

  ## Parameters

  - `client`: OpenAI LangChain client created with new/1
  - `messages`: List of messages in the conversation
  - `model`: OpenAI model to use (e.g. "gpt-4o", "gpt-4o-mini")
  - `opts`: Additional options for the completion request

  ## Options

  - `:temperature` - Controls randomness (0.0 to 2.0)
  - `:max_tokens` - Maximum number of tokens to generate

  ## Example

      iex> {:ok, client} = Alchemind.OpenAILangChain.new(api_key: "sk-...")
      iex> messages = [
      ...>   %{role: :system, content: "You are a helpful assistant."},
      ...>   %{role: :user, content: "Hello, world!"}
      ...> ]
      iex> Alchemind.OpenAILangChain.complete(client, messages, "gpt-4o", temperature: 0.7)
  """
  @impl Alchemind
  @spec complete(Client.t(), [Alchemind.message()], String.t(), keyword()) ::
          Alchemind.completion_result()
  def complete(%Client{} = client, messages, model, opts \\ []) do
    langchain_messages =
      Enum.map(messages, fn message ->
        case message.role do
          :system -> LangChain.Message.new_system!(message.content)
          :user -> LangChain.Message.new_user!(message.content)
          :assistant -> LangChain.Message.new_assistant!(message.content)
        end
      end)

    chat_model =
      if model != client.llm.model do
        %{client.llm | model: model}
      else
        client.llm
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

    chain =
      LangChain.Chains.LLMChain.new!(%{llm: chat_model})
      |> LangChain.Chains.LLMChain.add_messages(langchain_messages)

    try do
      case LangChain.Chains.LLMChain.run(chain) do
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

        {:error, %LangChain.Chains.LLMChain{}, %LangChain.LangChainError{} = error} ->
          {:error, %{error: error.message}}
      end
    rescue
      e in _ ->
        message = Exception.message(e)
        {:error, %{error: message}}
    catch
      type, value ->
        {:error, %{error: "Error: #{inspect(type)}, #{inspect(value)}"}}
    end
  end
end
