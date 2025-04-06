defmodule AlchemindIntegration.IntegrationCase do
  @moduledoc """
  This module defines the test case to be used by
  integration tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import AlchemindIntegration.IntegrationCase
    end
  end

  setup _tags do
    # Setup that is common for all integration tests
    # For example, starting apps, database setup, test fixtures, etc.

    {:ok, %{}}
  end
end
