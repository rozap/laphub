defmodule Laphub.Laps.Reducers.BatchUnfolder do
  require Logger
  alias Laphub.Laps.Sesh


  def init(%Sesh{} = sesh) do
    :nostate
  end

  def reduce(key, column, [value], state) do
    with {value, ""} <- Float.parse(value) do
      {[{key, column, value}], state}
    else
      _ ->
        Logger.warn("Dropping #{column} sample, cannot parse")
        {[], state}
    end
  end
end
