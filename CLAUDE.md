# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands
- `mix deps.get` - Install dependencies
- `mix compile` - Compile the project
- `mix format` - Format code
- `mix test` - Run all tests
- `mix test path/to/test_file.exs` - Run specific test file
- `mix test path/to/test_file.exs:42` - Run test at specific line

## Code Guidelines
- **Structure**: This is an Elixir umbrella project with apps in the `apps/` directory
- **Documentation**: Use `@moduledoc` and `@doc` with examples for doctests
- **Formatting**: Follow Elixir formatter settings in `.formatter.exs`
- **Naming**: Use snake_case for functions/variables, PascalCase for modules
- **Tests**: Write tests using ExUnit, include doctests when appropriate
- **Modules**: Keep modules focused on a single responsibility
- **Error Handling**: Use pattern matching and explicit error tuples (`{:ok, value}` or `{:error, reason}`)
- **Functions**: Prefer pipelines (|>) for data transformations