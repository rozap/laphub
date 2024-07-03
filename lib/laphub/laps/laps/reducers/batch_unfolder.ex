defmodule Laphub.Laps.Reducers.BatchUnfolder do
  require Logger
  alias Laphub.Laps.Sesh


  def init(%Sesh{} = _sesh, _db) do
    :nostate
  end

  def reduce(key, column, [value], state) do
    with {value, ""} <- Float.parse(value) do
      {[{key, column, value}], state}
    else
      _ ->
        Logger.warning("Dropping #{column} sample, cannot parse")
        {[], state}
    end
  end
end
