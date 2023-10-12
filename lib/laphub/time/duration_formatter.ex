defmodule Laphub.Time.DurationFormatter do
  @second 1_000
  @minute 60 * @second
  @hour @minute * 60
  @day @hour * 24
  @week @day * 7
  @month @day * 30
  @year @day * 365

  def format(millis),
    do: deconstruct(millis, []) |> Enum.reverse() |> do_format("")

  defp do_format([], acc), do: acc

  defp do_format([{unit, value} | rest], acc) do
    acc =
      case unit do
        :millisecond ->
          join_with(acc, ".", String.pad_leading(to_string(value), 3, "0"))

        :second ->
          join_with(acc, ":", String.pad_leading(to_string(value), 2, "0"))

        :minute ->
          join_with(acc, ":", to_string(value))

        :hour ->
          join_with(acc, ":", to_string(value))

        :day ->
          join_with(acc, "D", to_string(value))

        :week ->
          join_with(acc, "W", to_string(value))

        :month ->
          join_with(acc, "M", to_string(value))

        :year ->
          join_with(acc, "Y", to_string(value))

          # :second -> join_w
      end

    do_format(rest, acc)
  end

  defp join_with("", _sep, value), do: value
  defp join_with(acc, sep, value), do: acc <> sep <> value

  defp deconstruct(millis, components) do
    cond do
      millis >= @year ->
        deconstruct(rem(millis, @year), [{:year, div(millis, @year)} | components])

      millis >= @month ->
        deconstruct(rem(millis, @month), [{:month, div(millis, @month)} | components])

      millis >= @week ->
        deconstruct(rem(millis, @week), [{:week, div(millis, @week)} | components])

      millis >= @day ->
        deconstruct(rem(millis, @day), [{:day, div(millis, @day)} | components])

      millis >= @hour ->
        deconstruct(rem(millis, @hour), [{:hour, div(millis, @hour)} | components])

      millis >= @minute ->
        deconstruct(rem(millis, @minute), [{:minute, div(millis, @minute)} | components])

      millis >= @second ->
        deconstruct(rem(millis, @second), [{:second, div(millis, @second)} | components])

      true ->
        [{:millisecond, millis} | components]
    end
  end
end
