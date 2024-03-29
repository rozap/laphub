defmodule Laphub.Laps.Dashboard do
  use Ecto.Schema
  alias Laphub.Account.User
  import Ecto.Changeset

  defmodule DashWidget do
    use Ecto.Schema

    embedded_schema do
      field :title, :string
      field :component, :string
      field :columns, {:array, :string}
      field :style, :map
    end

    def changeset(model, params) do
      cast(model, params, [:title, :component, :columns, :style])
    end
  end

  schema "dashboards" do
    field :name, :string
    belongs_to :user, User
    embeds_many :widgets, DashWidget, on_replace: :delete
    timestamps()
  end

  def changeset(model, params) do
    cast(model, params, [:name])
    |> cast_embed(:widgets)
  end

  def default(user) do
    %__MODULE__{
      name: "Default",
      user_id: user.id,
      widgets: [
        %DashWidget{
          title: "drivers",
          component: "drivers",
          columns: ["drivers"],
          style: %{
            width: 4
          }
        },
        %DashWidget{
          title: "faults",
          component: "fault",
          columns: [],
          style: %{
            width: 4
          }
        },
        %DashWidget{
          title: "temperatures",
          component: "chart",
          columns: ["coolant_temp"],
          style: %{
            width: 4
          }
        },
        %DashWidget{
          title: "pressures",
          component: "chart",
          columns: ["oil_pres"],
          style: %{
            width: 4
          }
        },
        %DashWidget{
          title: "volts",
          component: "chart",
          columns: ["voltage"],
          style: %{
            width: 4
          }
        },
        %DashWidget{
          title: "rpm",
          component: "chart",
          columns: ["rpm"],
          style: %{
            width: 4
          }
        },
        %DashWidget{
          title: "speed",
          component: "chart",
          columns: ["speed"]
        },
        %DashWidget{
          title: "position",
          component: "map",
          columns: ["speed", "gps"]
        },
        %DashWidget{
          title: "laps",
          component: "laptimes",
          columns: ["laps"]
        }
      ]
    }
  end

  def reposition(dashboard, prev_posn, new_posn) do
    widget = Enum.at(dashboard.widgets, prev_posn)

    widgets =
      List.delete_at(dashboard.widgets, prev_posn)
      |> List.insert_at(new_posn, widget)

    changeset(dashboard, %{
    })
    |> put_embed(:widgets, widgets)
  end
end
