defmodule LaphubWeb.Components.Util do
  def classnames(map) do
    map
    |> Enum.filter(fn {_class, enabled} -> enabled end)
    |> Enum.map(fn {class, _} -> class end)
  end
end
