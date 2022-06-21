defmodule Laphub.Repo.Migrations.AddAccounts do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :display_name, :string
      add :password, :string
      add :role, :string
      add :is_admin, :boolean

      add :bio_text, :text
      add :bio_image, :string
      add :user_slug, :string
      add :last_notification_check, :utc_datetime

      timestamps()
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:display_name], name: :uniq_username)
    create unique_index(:users, [:user_slug], name: :uniq_username_slug)


    create table(:sessions) do
      add :uuid, :string
      add :deleted_at, :utc_datetime
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:sessions, [:uuid])
    create index(:sessions, [:user_id])

    create table(:password_resets) do
      add :uid, :string
      add :owner_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:password_resets, [:owner_id])
    create index(:password_resets, [:uid])
  end
end
