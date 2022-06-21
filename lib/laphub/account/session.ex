defmodule Laphub.Account.Session do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias Laphub.Account.{Session, User}

  schema "sessions" do
    field :deleted_at, :utc_datetime
    field :uuid, :string
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(%Session{} = session, attrs) do
    session
    |> cast(attrs, [:deleted_at])
    |> validate_required([:uuid])
    |> unique_constraint(:uuid)
  end

  def new(session_id, %User{id: user_id}) do
    changeset(
      %Session{
        uuid: session_id,
        user_id: user_id
      },
      %{}
    )
  end

  def by_token(token) do
    from(s in Session,
      where: s.uuid == ^token and is_nil(s.deleted_at),
      join: u in assoc(s, :user),
      preload: :user
    )
  end

  def delete(%Session{} = session) do
    changeset(session, %{deleted_at: DateTime.utc_now()})
  end
end
