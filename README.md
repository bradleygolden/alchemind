# Alchemind

A unified interface for Large Language Models (LLMs) in Elixir.

## Overview

Alchemind provides a consistent API for interacting with various LLM providers, making it easy to switch between different models or use multiple providers in the same application. Inspired by libraries like LiteLLM and LlamaIndex, Alchemind abstracts away provider-specific details to give you a clean, uniform experience.

## Features

- **Provider-agnostic API**: Write code once, use with any supported LLM provider
- **Simple client interface**: Easy-to-use functions for common LLM operations
- **Extensible architecture**: Umbrella project structure makes adding new providers straightforward
- **Type safety**: Consistent type specifications across the API
- **Comprehensive documentation**: Detailed docs and examples for all modules
- **Streaming support**: Stream responses token by token for real-time interaction

## Supported Providers

Currently, Alchemind supports the following providers:

- **OpenAI** (`alchemind_openai`): Access to GPT models through OpenAI's API
- **OpenAI LangChain** (`alchemind_openai_langchain`): Access to OpenAI's API via LangChain integration

More providers are planned for future releases.

## Provider Capabilities

| Provider | Package | Chat Completions | Streaming | Speech to Text | Text to Speech |
|----------|---------|:----------------:|:---------:|:--------------:|:--------------:|
| OpenAI | `alchemind_openai` | ✅ | ❌ | ✅ | ✅ |
| OpenAI LangChain | `alchemind_openai_langchain` | ✅ | ✅ | ❌ | ❌ |

## Basic Usage

Here's a quick example of how to use Alchemind with OpenAI:

```elixir
# Create a client
{:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: "your-api-key")

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

## Streaming Usage

You can also stream responses token by token for real-time interaction:

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

## Speech to Text Usage

You can transcribe audio to text using providers that support speech-to-text capabilities:

```elixir
# Create a client
{:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: "your-api-key")

# Read audio file
audio_binary = File.read!("speech.mp3")

# Transcribe audio to text
{:ok, text} = Alchemind.transcribe(client, audio_binary, language: "en")

IO.puts("Transcription: #{text}")
```

## Text to Speech Usage

You can convert text to speech using providers that support text-to-speech capabilities:

```elixir
# Create a client
{:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: "your-api-key")

# Convert text to speech
{:ok, audio_binary} = Alchemind.tts(client, "Hello, welcome to Alchemind!", voice: "nova")

# Save the audio to a file
File.write!("output.mp3", audio_binary)
```

## Architecture

Alchemind is structured as an Elixir umbrella application with these components:

- `alchemind`: Core interfaces, behaviors, and types
- `alchemind_openai`: OpenAI provider implementation
- `alchemind_openai_langchain`: OpenAI implementation via LangChain

## Development

### Prerequisites

- Elixir 1.18 or later
- Erlang OTP 26 or later

### Running Tests

```bash
# Run unit tests
mix test

# Run integration tests (requires API keys)
cd integration_test && mix test
```

## Release Guidelines

When preparing a new release, please follow these guidelines to ensure consistency:

### Version Management

1. **SemVer Compliance**: Follow [Semantic Versioning](https://semver.org/) strictly:
   - MAJOR: incompatible API changes
   - MINOR: backward-compatible functionality
   - PATCH: backward-compatible bug fixes

2. **Version Management**:
   - Update version in root `/mix.exs` for the umbrella project
   - Update version in each app's `mix.exs` based on their individual changes
   - Apps can have independent version numbers based on their development cycle
   - Consider using a version prefix (e.g., `alchemind-x.y.z`) in changelogs to distinguish between app versions

### Code Style

1. **Formatting and Comments**:
   - Follow the Elixir formatter rules defined in .formatter.exs
   - Do not add comments to code unless strictly necessary for context
   - Self-documenting code with clear function names is preferred
   - Use module and function documentation (@moduledoc and @doc) instead of inline comments

### Changelog Management

1. **Update All CHANGELOG.md Files**:
   - Update the root `/CHANGELOG.md` with high-level changes
   - Update each app's CHANGELOG.md in its respective directory
   - Document changes under the appropriate heading (Added, Changed, Fixed, etc.)
   - Include the new version number and date
   - Keep an [Unreleased] section for tracking current changes
   - Follow the [Keep a Changelog](https://keepachangelog.com/) format

2. **CHANGELOG Structure**:
   - Root CHANGELOG.md provides high-level overview with links to app-specific changelogs
   - Each app directory contains its own detailed CHANGELOG.md file
   - Use relative links in the root changelog to reference app-specific changes

3. **Entry Format**:
   - Use present tense, imperative style (e.g., "Add feature" not "Added feature")
   - Include issue/PR numbers where applicable
   - Group related changes

### Release Process

1. **Before Release**:
   - Run `mix test` to ensure all tests pass
   - Run `mix format` to ensure code is properly formatted
   - Run integration tests: `cd integration_test && mix test`
   - Verify documentation is up-to-date (README.md and @doc/@moduledoc)
   - Verify CHANGELOG.md is updated

2. **Release Commits**:
   - Create version bump commits:
     - Update each app's `mix.exs` version based on its changes
     - Update the app's CHANGELOG.md accordingly
     - Update the root `/mix.exs` version when making a project-wide release
     - Update the root CHANGELOG.md to reference app-specific changes
   - For each release:
     - Move [Unreleased] changes to the new version section
     - Add a new empty [Unreleased] section
     - Update version comparison links
   - Tag the commit with the appropriate version number:
     - Project-wide release: `v0.1.0` format
     - App-specific release: `appname-v0.1.0` format (e.g., `alchemind-v0.1.0`)

3. **After Release**:
   - Push changes and tags: `git push && git push --tags`
   - If publishing to Hex, run `mix hex.publish` (consider `mix hex.publish --umbrella` for all apps)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Alchemind is released under the MIT License. See [LICENSE](LICENSE) for details.