defmodule Laphub.Laps.Sesh do
  use Ecto.Schema
  import Ecto.Changeset

  schema "lap_sesh" do
    field :title, :string
    field :track_id, :id
    field :user_id, :id

    timestamps()
  end

  @doc false
  def changeset(sesh, attrs) do
    sesh
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end
end
