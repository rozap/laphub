defmodule Laphub.Repo.Migrations.AddDashboards do
  use Ecto.Migration

  def change do
    create table(:dashboards) do
      add :name, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :widgets, {:array, :map}
    end
  end
end
