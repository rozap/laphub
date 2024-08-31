defmodule Laphub.Laps.Teammate do
  use Ecto.Schema
  import Ecto.Changeset
  alias Laphub.Laps.Team
  alias Laphub.Account.User

  schema "teammates" do
    belongs_to :user, User
    belongs_to :team, Team

    timestamps()
  end
end
