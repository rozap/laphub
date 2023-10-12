defmodule DurationFormatTest do
  use ExUnit.Case, async: true
  alias Laphub.Time.DurationFormatter

  test "can format a duration" do
    assert DurationFormatter.format((1000 * 60 * 2 + (1050))) == "2:01.050"
    assert DurationFormatter.format((1000 * 60 * 3 + (1082))) == "3:01.082"
    assert DurationFormatter.format((1000 * 60 * 3 + (9982))) == "3:09.982"

  end
end
