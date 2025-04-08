# Alchemind

Core library for the Alchemind project that provides interfaces, behaviors, and types for LLM interactions.

> [!WARNING]  
> This project is currently in early development and should not be used in production environments.

## Overview

This is the core package of the Alchemind umbrella application, containing the foundational components that all provider-specific implementations build upon. It defines the common interfaces and behaviors that ensure a consistent API across different LLM providers.

## Features

- Common type definitions for LLM interactions
- Behavior modules that provider implementations must conform to
- Core utilities and helper functions

## Usage

This package is primarily used by other Alchemind packages and is not typically used directly. However, you can use the core interfaces to implement your own provider:

```elixir
defmodule YourCustomProvider do
  @behaviour Alchemind.Provider
  
  # Implement the required callbacks
  # ...
end
```

## Installation

The package can be installed by adding `alchemind` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:alchemind, "~> 0.1.0-rc1"}
  ]
end
```

## Development

You can run tests specifically for this core package with:

```bash
cd apps/alchemind
mix test
```

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc):

```bash
cd apps/alchemind
mix docs
```