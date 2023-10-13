defmodule LaphubWeb.Components.WidgetUtil do
  alias Laphub.Laps.ActiveSesh
  alias Laphub.Time

  def clamp_range(pid) do
    {from_key, to_key} = ActiveSesh.range(pid)
    clamped_from = Time.subtract(to_key, 60 * 3)
    from = max(clamped_from, from_key)
    {from, to_key}
  end
end
