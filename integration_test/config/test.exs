import Config

config :logger, level: :warning

openai_api_key =
  System.get_env("OPENAI_API_KEY", "test_api_key") || raise("OPENAI_API_KEY is not set")

config :alchemind_openai,
  api_key: openai_api_key,
  api_url: System.get_env("OPENAI_API_URL", "https://api.openai.com/v1"),
  organization_id: System.get_env("OPENAI_ORGANIZATION_ID"),
  default_model: System.get_env("OPENAI_DEFAULT_MODEL", "gpt-4o-mini"),
  timeout: 60_000

config :alchemind_openai_langchain,
  api_key: openai_api_key,
  base_url: System.get_env("OPENAI_API_URL", "https://api.openai.com/v1"),
  default_model: System.get_env("OPENAI_DEFAULT_MODEL", "gpt-4o-mini"),
  timeout: 60_000
