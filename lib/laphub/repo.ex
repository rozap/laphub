defmodule Laphub.Repo do
  use Ecto.Repo,
    otp_app: :laphub,
    adapter: Ecto.Adapters.Postgres
end
