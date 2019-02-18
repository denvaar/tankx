defmodule TanksServer.Repo do
  use Ecto.Repo,
    otp_app: :tanks_server,
    adapter: Ecto.Adapters.Postgres
end
