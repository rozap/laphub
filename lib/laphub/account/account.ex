defmodule Laphub.Account do
  @moduledoc """
  The Account context.
  """
  import Ecto.Query, warn: false
  alias Laphub.Repo
  alias Laphub.Util
  require Logger
  alias Laphub.Account.{User, Session, Subscription, PasswordReset}
  import LaphubWeb.Gettext
  import Ecto.Changeset

  def create_reset(%User{} = user) do
    Repo.insert(PasswordReset.new(user))
  end

  def lookup_reset(uid) do
    Repo.one(
      from pr in PasswordReset,
        inner_join: o in assoc(pr, :owner),
        where: pr.uid == ^uid,
        preload: [owner: o]
    )
  end

  def list_user do
    Repo.all(User)
  end

  def new_user(params) do
    case User.changeset(%User{}, params) do
      %{valid?: true} = cset ->
        candidate_username = String.downcase(get_field(cset, :display_name))
        candidate_email = String.downcase(get_field(cset, :email))

        case Repo.one(
               from u in User,
                 where:
                   fragment("lower(?)", u.display_name) == ^candidate_username or
                     fragment("lower(?)", u.email) == ^candidate_email
             ) do
          %User{} = taken ->
            cset =
              if String.downcase(taken.email) == candidate_email do
                add_error(cset, :email, dgettext("errors", "that email has already been taken"))
              else
                cset
              end

            cset =
              if String.downcase(taken.display_name) == candidate_username do
                add_error(
                  cset,
                  :display_name,
                  dgettext("errors", "that username has already been taken")
                )
              else
                cset
              end

            cset
            |> Map.put(:action, :insert)

          _ ->
            cset
        end

      cset ->
        cset
    end
  end

  def get_user_by_email(email) do
    Repo.one(from u in User, where: u.email == ^email)
  end

  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> User.hash_password()
    |> Repo.insert()
  end

  def update_user(changeset) do
    changeset
    |> User.hash_password()
    |> Repo.update()
  end

  def read_notifications(%User{} = user) do
    user
    |> User.changeset(%{last_notification_check: DateTime.utc_now()})
    |> update_user()
  end

  def redeem_reset(%PasswordReset{} = pr, cset) do
    Repo.transaction(fn ->
      {:ok, _user} = update_user(cset)
      Repo.delete!(pr)
    end)
  end

  def change_user(cset_or_user, attrs) do
    cset_or_user
    |> Util.clear_errors()
    |> User.changeset(attrs)
    |> Map.put(:action, :update)
  end

  def show_user(%User{id: id}) do
    case Repo.one(User.by_id(id)) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def is_valid_email_password?(email, password) do
    with %User{} = user <- email |> User.lookup() |> Repo.one() do
      Comeonin.Argon2.checkpw(password, user.password)
    else
      _ -> false
    end
  end

  def login(_session_id, email, password) do
    with %User{} = user <- email |> User.lookup() |> Repo.one() do
      case Comeonin.Argon2.checkpw(password, user.password) do
        true ->
          {:ok, user}

        false ->
          {:error, :invalid_password}
      end
    else
      nil -> {:error, :not_found}
    end
  end

  def insert_session(session_id, user) do
    with {:ok, session} <- Repo.insert(Session.new(session_id, user)) do
      {:ok, session, user}
    end
  end

  def logout(nil), do: :ok

  def logout(session) do
    Repo.delete!(session)
    :ok
  end

  def from_token(nil), do: {:error, :invalid_token}

  def from_token(token) do
    case Repo.one(Session.by_token(token)) do
      %Session{} = session -> {:ok, session}
      nil -> {:error, :invalid_token}
    end
  end

  def lookup_user(slug) do
    Repo.one(
      from u in User,
        where: u.user_slug == ^slug
    )
  end

  def empty_subscription(
        %User{} = user,
        stripe_customer
      ) do
    Repo.insert!(
      Subscription.new(user, %{
        stripe_subscription_id: nil,
        stripe_current_period_end: nil,
        stripe_customer: stripe_customer,
        stripe_price_id: nil,
        stripe_payment_method_id: nil
      })
    )
  end

  def create_subscription(
        %User{} = user,
        %{
          stripe_subscription_id: _,
          stripe_current_period_end: _,
          stripe_customer: _,
          stripe_price_id: _,
          stripe_payment_method_id: _
        } = stripe_params
      ) do
    Repo.transaction(fn ->
      with %Subscription{} = sub <- Repo.one(Subscription.for_user(user)) do
        Repo.delete!(sub)
      end

      Repo.insert!(
        Subscription.new(
          user,
          stripe_params
        )
      )
    end)
  end

  def get_subscription(%User{} = user) do
    Repo.one(Subscription.for_user(user))
  end

  def payout(from_customer_id) do
    case Repo.one(Subscription.by_customer_id(from_customer_id)) do
      %Subscription{deleted_at: nil} ->
        :ok

      %Subscription{id: id} ->
        Logger.warn("Payout for deleted Subscription(#{id})")
    end
  end

  defimpl Jason.Encoder, for: Session do
    def encode(model, _options) do
      model
      |> Map.take([:uuid])
      |> Jason.encode!()
    end
  end
end
