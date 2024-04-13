defmodule Laphub.Laps.Dashboard do
  use Ecto.Schema
  alias Laphub.Account.User
  import Ecto.Changeset

  defmodule DashWidget do
    use Ecto.Schema

    @derive Jason.Encoder
    embedded_schema do
      field :title, :string
      field :component, :string
      field :columns, {:array, :string}
      field :units, :string
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
          units: "degrees_f",
          style: %{
            width: 4,
            colors: %{
              "coolant_temp" => "red"
            }
          }
        },
        %DashWidget{
          title: "pressures",
          component: "chart",
          columns: ["oil_pres"],
          units: "pressure_psi",
          style: %{
            width: 4,
            colors: %{
              "oil_pres" => "blue"
            }
          }
        },
        %DashWidget{
          title: "air-fuel",
          component: "chart",
          columns: ["air_fuel_ratio"],
          units: nil,
          style: %{
            width: 4,
            colors: %{
              "air_fuel_ratio" => "orange"
            }
          }
        },
        %DashWidget{
          title: "fuel level",
          component: "chart",
          columns: ["fuel_level"],
          units: nil,
          style: %{
            width: 4,
            colors: %{
              "fuel_level" => "brown"
            }
          }
        },
        %DashWidget{
          title: "volts",
          component: "chart",
          columns: ["voltage"],
          units: "volts",
          style: %{
            width: 4,
            colors: %{
              "voltage" => "green"
            }
          }
        },
        %DashWidget{
          title: "rpm",
          component: "chart",
          columns: ["rpm"],
          style: %{
            width: 4,
            colors: %{
              "rpm" => "cyan"
            }
          }
        },
        %DashWidget{
          title: "speed",
          component: "chart",
          columns: ["speed"],
          style: %{
            width: 4,
            colors: %{
              "speed" => "pink"
            }
          }
        },
        %DashWidget{
          title: "position",
          component: "map",
          columns: ["speed", "gps"],
          style: %{
            width: 8
          }
        },
        %DashWidget{
          title: "laps",
          component: "laptimes",
          columns: ["laps"],
          style: %{
            width: 4
          }

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
