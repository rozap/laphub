defmodule LaphubWeb.LiveUtil do
  @doc """
  use like

  <.some_component class={classest([{"some-class", true}, {"another-class", false}])}
  """
  def classes(classes) do
    classes
    |> Enum.filter(fn
      {_, c} -> c
      _ -> true
    end)
    |> Enum.map(fn
      {n, _} -> n
      n -> n
    end)
    |> Enum.join(" ")
  end
end
