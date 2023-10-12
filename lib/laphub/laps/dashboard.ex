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
  end

  schema "dashboards" do
    field :name, :string
    belongs_to :user, User
    embeds_many :widgets, DashWidget
  end

  def changeset(model, params) do
    cast(model, params, [:name])
    |> cast_embed(:widgets)
  end

  def default() do
    %__MODULE__{
      name: "Default",
      widgets: [
        %DashWidget{
          title: "drivers",
          component: "drivers",
          columns: ["drivers"],
          style: %{
            width: "50%"
          }
        },
        %DashWidget{
          title: "faults",
          component: "fault",
          columns: [],
          style: %{
            width: "50%"
          }
        },


        %DashWidget{
          title: "temperatures",
          component: "chart",
          columns: ["coolant_temp"]
        },
        %DashWidget{
          title: "pressures",
          component: "chart",
          columns: ["oil_pres"]
        },
        %DashWidget{
          title: "volts",
          component: "chart",
          columns: ["voltage"]
        },
        %DashWidget{
          title: "rpm",
          component: "chart",
          columns: ["rpm"]
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
end
