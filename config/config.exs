import Config

# tai can't switch adapters at runtime
config :tai, order_repo_adapter: Ecto.Adapters.Postgres

# ecto_repos can't be detected in runtime.exs
if config_env() == :dev do
  config :phoenix, :json_library, Jason

  config :desk, ecto_repos: [Tai.Orders.OrderRepo, Workbench.Repo, History.Repo]
end
