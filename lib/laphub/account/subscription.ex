defmodule Laphub.Account.Subscription do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias Laphub.Account.{User}

  schema "subscriptions" do
    field :deleted_at, :utc_datetime
    field :billing_uid, :string
    belongs_to :user, User

    field :stripe_subscription_id, :string
    field :stripe_current_period_end, :integer
    field :stripe_customer, :string
    field :stripe_price_id, :string
    # field :stripe_billing_name
    field :stripe_payment_method_id, :string

    timestamps()
  end

  def changeset(%__MODULE__{} = sub, attrs) do
    cast(sub, attrs, [])
  end

  def new(
        %User{id: user_id},
        %{
          stripe_subscription_id: stripe_subscription_id,
          stripe_current_period_end: stripe_current_period_end,
          stripe_customer: stripe_customer,
          stripe_price_id: stripe_price_id,
          stripe_payment_method_id: stripe_payment_method_id
        }
      ) do
    changeset(
      %__MODULE__{
        billing_uid: UUID.uuid4(),
        user_id: user_id,
        stripe_subscription_id: stripe_subscription_id,
        stripe_current_period_end: stripe_current_period_end,
        stripe_customer: stripe_customer,
        stripe_price_id: stripe_price_id,
        stripe_payment_method_id: stripe_payment_method_id
      },
      %{}
    )
  end

  def for_user(%User{id: user_id}) do
    from s in __MODULE__, where: s.user_id == ^user_id
  end

  def by_customer_id(from_customer_id) do
    from s in __MODULE__, where: s.stripe_customer == ^from_customer_id
  end
end
