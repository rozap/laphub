defmodule Laphub.Laps.Team do
  use Ecto.Schema
  import Ecto.Changeset
  alias Laphub.Laps.{Teammate, Track}
  alias Laphub.Account.User

  schema "teams" do
    field :name, :string
    field :description, :string
    field :avatar, :string
    belongs_to :owner, User

    has_many :teammates, Teammate
    has_many :teammates_users, through: [:teammates, :user]

    timestamps()
  end

  @doc false
  def changeset(sesh, attrs) do
    sesh
    |> cast(attrs, [:name, :description, :avatar])
    |> validate_required([
      :name, :description
    ])
  end

  def new(user) do
    changeset(
      %__MODULE__{
        owner_id: user.id,
      },
      %{}
    )
  end
end
