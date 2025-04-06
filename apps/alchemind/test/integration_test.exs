defmodule Alchemind.IntegrationTest do
  @moduledoc """
  Integration tests for using Alchemind with different providers.

  These tests are tagged with :integration and are excluded by default.
  To run them, use: mix test --include integration
  """

  use ExUnit.Case, async: false

  @moduletag :integration

  describe "OpenAI integration" do
    @tag :skip
    test "complete a conversation" do
      messages = [
        %{role: :system, content: "You are a helpful assistant."},
        %{role: :user, content: "Say hello in exactly 5 words."}
      ]

      api_key = System.get_env("OPENAI_API_KEY")
      assert api_key, "OPENAI_API_KEY environment variable must be set"

      {:ok, client} = Alchemind.new(Alchemind.OpenAI, api_key: api_key)

      {:ok, response} = Alchemind.complete(client, messages, "gpt-4o", temperature: 0)

      assert is_map(response)
      assert is_binary(response.id)
      assert is_binary(response.model)
      assert is_list(response.choices)
      assert length(response.choices) > 0

      assistant_message = response.choices |> List.first() |> Map.get(:message)
      assert assistant_message.role == :assistant
      assert is_binary(assistant_message.content)

      words =
        assistant_message.content
        |> String.split(~r/\s+/)
        |> Enum.filter(&(&1 != ""))

      assert length(words) == 5
    end
  end
end
