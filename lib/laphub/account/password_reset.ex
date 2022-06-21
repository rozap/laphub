defmodule Laphub.Account.PasswordReset do
  use Ecto.Schema
  alias Laphub.Account.User

  schema "password_resets" do
    field :uid, :string
    belongs_to :owner, User

    timestamps()
  end

  def new(%User{id: owner_id}) do
    %__MODULE__{owner_id: owner_id, uid: UUID.uuid4()}
  end
end
