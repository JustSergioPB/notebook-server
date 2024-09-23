defmodule NotebookServer.Repo do
  use Ecto.Repo,
    otp_app: :notebook_server,
    adapter: Ecto.Adapters.Postgres
end
