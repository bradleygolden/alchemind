# Alchemind OpenAI LangChain

OpenAI provider implementation for the Alchemind project using LangChain.

## Overview

This package implements the Alchemind interfaces for OpenAI's API using the LangChain integration. It provides access to OpenAI models with streaming support through the LangChain library, allowing for real-time token-by-token responses.

## Features

- Chat completions with GPT models
- Streaming support for real-time responses
- Full implementation of the `Alchemind.Provider` behavior
- Integration with LangChain for additional features

## Capabilities

| Capability | Support |
|------------|:-------:|
| Chat Completions | ✅ |
| Streaming | ✅ |
| Speech to Text | ❌ |
| Text to Speech | ❌ |

## Usage

### Basic Usage

```elixir
# Create an OpenAI LangChain client
{:ok, client} = Alchemind.new(Alchemind.OpenAILangChain, api_key: "your-api-key")

# Define conversation messages
messages = [
  %{role: :system, content: "You are a helpful assistant."},
  %{role: :user, content: "What is the capital of France?"}
]

# Get a completion
{:ok, response} = Alchemind.complete(client, messages, "gpt-4o")

# Extract the assistant's message
assistant_message = 
  response.choices
  |> List.first()
  |> Map.get(:message)
  |> Map.get(:content)

IO.puts("Response: #{assistant_message}")
```

### Streaming Usage

```elixir
# Create a client
{:ok, client} = Alchemind.new(Alchemind.OpenAILangChain, api_key: "your-api-key")

# Define conversation messages
messages = [
  %{role: :system, content: "You are a helpful assistant."},
  %{role: :user, content: "Write a poem about coding in Elixir."}
]

# Define a callback function to handle streaming deltas
callback = fn delta -> 
  if delta.content, do: IO.write(delta.content)
end

# Stream a completion using the same complete function with a callback
{:ok, response} = Alchemind.complete(client, messages, "gpt-4o", callback)

# Final response is also returned after streaming completes
IO.puts("\n\nFinal response:")
assistant_message = 
  response.choices
  |> List.first()
  |> Map.get(:message)
  |> Map.get(:content)
IO.puts(assistant_message)
```

## Configuration

You can configure the OpenAI LangChain provider when creating a client:
```elixir
{:ok, client} = Alchemind.new(Alchemind.OpenAILangChain, 
  api_key: "your-api-key",
  organization_id: "your-org-id" # Optional
)
```

## Installation

The package can be installed by adding `alchemind_openai_langchain` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:alchemind, "~> 0.1.0"},
    {:alchemind_openai_langchain, "~> 0.1.0"}
  ]
end
```

## Development

You can run tests specifically for this package with:

```bash
cd apps/alchemind_openai_langchain
mix test
```

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc):

```bash
cd apps/alchemind_openai_langchain
mix docs
``` 