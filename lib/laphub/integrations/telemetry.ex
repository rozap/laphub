defmodule Laphub.Integrations.Telemetry do
  defmodule Position do
    defstruct [
      :best_lap,
      :best_lap_time,
      :current_lap,
      :heading,
      :accuracy,
      :map,
      :speed,
      :status,
      :top_speed,
      :lat,
      :lon,
      :online
    ]
  end

end