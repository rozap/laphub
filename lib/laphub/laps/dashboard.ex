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

  @colors [
    "#0d0305",
    "#3c3444",
    "#6e576e",
    "#917d9b",
    "#5f4f47",
    "#851246",
    "#d72048",
    "#7d322f",
    "#9d4c2f",
    "#c65e2d",
    "#f96a2d",
    "#ffa300",
    "#e29138",
    "#f7c233",
    "#11442c",
    "#287a33",
    "#52b139",
    "#8ae931",
    "#0e131e",
    "#203c62",
    "#2a69b0",
    "#00a1de",
    "#6bdad5",
    "#a52eb8",
    "#f7406e",
    "#fc83a2",
    "#fba176"
  ]

  def default(user) do
    %__MODULE__{
      name: "Default",
      user_id: user.id,
      widgets: [
        # %DashWidget{
        #   title: "video",
        #   component: "video",
        #   columns: [],
        #   style: %{
        #     "width" => 4
        #   }
        # },
        # %DashWidget{
        #   title: "drivers",
        #   component: "drivers",
        #   columns: ["drivers"],
        #   style: %{
        #     "width" => 4
        #   }
        # },
        %DashWidget{
          title: "faults",
          component: "fault",
          columns: [],
          style: %{
            "width" => 4
          }
        },
        # %DashWidget{
        #   title: "position",
        #   component: "map",
        #   columns: ["speed", "gps"],
        #   style: %{
        #     "width" => 4
        #   }
        # },
        # %DashWidget{
        #   title: "laps",
        #   component: "laptimes",
        #   columns: ["laps"],
        #   style: %{
        #     "width" => 4
        #   }
        # }
      ]
    }
  end

  def reposition(dashboard, prev_posn, new_posn) do
    widget = Enum.at(dashboard.widgets, prev_posn)

    widgets =
      List.delete_at(dashboard.widgets, prev_posn)
      |> List.insert_at(new_posn, widget)

    changeset(dashboard, %{})
    |> put_embed(:widgets, widgets)
  end

  defp random_color(existing) do
    used = Enum.flat_map(existing, fn w ->
      case w do
        %{style: %{"colors" => m}} -> Map.values(m)
        _ -> []
      end
    end)
    |> MapSet.new()

    @colors
    |> Enum.reject(fn c -> MapSet.member?(used, c) end)
    |> Enum.random()
  end

  def add_chart(dashboard, column) do
    w = %DashWidget{
      title: column,
      component: "chart",
      columns: [column],
      style: %{
        width: 4,
        colors: %{
          column => random_color(dashboard.widgets)
        }
      }
    }

    changeset(dashboard, %{})
    |> put_embed(:widgets, dashboard.widgets ++ [w])
  end

  def remove_chart(dashboard, column) do
    changeset(dashboard, %{})
    |> put_embed(
      :widgets,
      Enum.reject(dashboard.widgets, fn w ->
        column in w.columns
      end)
    )
  end
end
