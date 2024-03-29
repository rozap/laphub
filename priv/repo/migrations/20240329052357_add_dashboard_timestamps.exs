defmodule Laphub.Repo.Migrations.AddDashboardTimestamps do
  use Ecto.Migration

  def change do
    alter table(:dashboards) do
      timestamps()
    end
  end
end
