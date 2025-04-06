# Alchemind Integration Tests

This directory contains integration tests for the Alchemind project, focused on testing the interaction between different applications in the umbrella project.

## Purpose

Unlike unit tests that test individual components in isolation, these integration tests verify that the different applications work together correctly. This includes:

- Testing cross-application interactions
- Verifying API client functionality with real external services
- Testing end-to-end workflows

## Running Tests

These tests require real API credentials to run successfully:

```bash
# Set your API key (required for OpenAI API tests)
export OPENAI_API_KEY=your_api_key_here

# Run all tests
cd integration_test
mix test
```

To run a specific test file:

```bash
mix test test/integration/openai_integration_test.exs
```

**Note:** Running tests will consume API usage and may incur costs depending on your API plan.

## OpenAI Integration Tests

The OpenAI integration tests verify that our application can correctly:

1. Create an OpenAI client
2. Send requests to the OpenAI API
3. Process responses from the API
4. Handle API errors appropriately

If you run the tests without setting the `OPENAI_API_KEY` environment variable, most of the OpenAI API tests will fail as expected. Only the client creation tests and error handling test will pass.

## Project Structure

- `/lib` - Helper modules for integration testing
- `/test/support` - Support modules and fixtures for tests
- `/test/integration` - The actual integration test files

## Writing Integration Tests

When writing integration tests:

1. Use `AlchemindIntegration.IntegrationCase` as the base for test modules
2. Write tests to capture how the application would be used in the real world
3. Use appropriate assertions to verify that the interactions work as expected

## Environment Variables

The following environment variables are used by the integration tests:

| Variable | Purpose | Required For |
|----------|---------|-------------|
| `OPENAI_API_KEY` | OpenAI API key | Running OpenAI API tests successfully |
| `OPENAI_ORGANIZATION_ID` | OpenAI organization ID (optional) | None - Optional parameter |

