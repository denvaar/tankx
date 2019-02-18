# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :tanks_server,
  ecto_repos: [TanksServer.Repo]

# Configures the endpoint
config :tanks_server, TanksServerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "9d0jL2aghiBYS5rxQByqE/YKa4i4TAxGOd9nkCDurQRituvoz9cf3C3E7Vp/kx+V",
  render_errors: [view: TanksServerWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: TanksServer.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
