defmodule LaphubWeb.Icons do
  use Phoenix.LiveComponent

  @icons [
    "heart",
    "home",
    "book",
    "compass",
    "bell",
    "delete",
    "circle_x",
    "wrench",
    "arrow_right",
    "arrow_left",
    "question_mark"
  ]

  Enum.each(@icons, fn name ->
    def unquote(String.replace(name, "-", "_") |> String.to_atom())(assigns) do
      name = unquote(name)
      class = Enum.join(["icon" | List.wrap(Map.get(assigns, :class, []))], " ")

      ~H"""
      <svg viewBox="0 0 8 8" class={class}>
        <use xlink:href={"##{name}"} class={"icon-#{name}"}></use>
      </svg>
      """
    end
  end)


  @usages Enum.map(@icons, fn name ->
            path =
              Path.join([
                :code.priv_dir(:laphub),
                "icons",
                "path-#{String.replace(name, "_", "-")}.svg"
              ])

            {name, path}
          end)
  def used_icons(), do: @usages
end
