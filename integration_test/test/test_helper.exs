ExUnit.configure(
  timeout: 120_000,
  trace: true,
  formatters: [ExUnit.CLIFormatter]
)

ExUnit.start()

{:ok, _} = Application.ensure_all_started(:alchemind)
{:ok, _} = Application.ensure_all_started(:alchemind_openai)
