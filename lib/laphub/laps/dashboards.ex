defmodule Laphub.Laps.Dashboards do
  alias Laphub.Laps.Dashboard
  alias Laphub.Repo
  import Ecto.Query
  alias Laphub.Account.User

  def get_or_create_default(%User{id: user_id} = user) do
    case Repo.one(from d in Dashboard, where: d.user_id == ^user_id, order_by: [desc: d.inserted_at], limit: 1) do
      nil ->
        Repo.insert!(Dashboard.default(user))
      d ->
        d
    end
  end
end
