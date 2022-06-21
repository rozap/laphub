defmodule Laphub.Account.User do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias Laphub.Account.User

  schema "users" do
    field :email, :string
    field :display_name, :string
    field :user_slug, :string
    field :password, :string
    field :plain_password, :string, virtual: true

    field :role, :string, default: @consumer
    field :is_admin, :boolean, default: false

    field :bio_text, :string
    field :bio_image, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    cset =
      user
      |> cast(attrs, [
        :email,
        :display_name,
        :plain_password,
        :bio_text,
        :bio_image
      ])
      |> validate_password(:plain_password)
      |> validate_required([:email, :display_name])
      |> unique_constraint(:email)
      |> unique_constraint(:display_name, name: :uniq_username)
      |> unique_constraint(:user_slug, name: :uniq_username_slug)
      |> validate_length(:bio_text, min: 0, max: 250)

    case {user, get_field(cset, :display_name)} do
      {%User{user_slug: nil}, display_name} when is_binary(display_name) ->
        put_change(cset, :user_slug, Slugger.slugify(display_name))

      _ ->
        cset
    end
  end

  defp join_related(q) do
    q
  end

  defp preload_related(q) do
    q
  end

  def lookup(email) do
    from(u in User, where: u.email == ^email)
    |> join_related
    |> preload_related
  end

  def by_id(id) do
    from(u in User, where: u.id == ^id)
    |> join_related
    |> preload_related
  end

  def validate_password(changeset, field, options \\ []) do
    validate_change(changeset, field, fn _, password ->
      case valid_password?(password) do
        {:ok, _} -> []
        {:error, msg} -> [{field, options[:message] || msg}]
      end
    end)
  end

  defp valid_password?(password) when byte_size(password) > 7 do
    {:ok, password}
  end

  defp valid_password?(_), do: {:error, "your password is too short"}

  def hash_password(
        %Ecto.Changeset{valid?: true, changes: %{plain_password: password}} = changeset
      )
      when is_binary(password) do
    change(changeset, %{password: Comeonin.Argon2.hashpwsalt(password)})
  end

  def hash_password(changeset), do: changeset

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(model, _opts) do
      model
      |> Map.take([
        :email,
        :inserted_at,
        :updated_at,
        :display_name,
        :id
      ])
      |> Jason.encode!()
    end
  end
end
