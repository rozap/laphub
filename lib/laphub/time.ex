defmodule Laphub.Time do
  def to_key(%NaiveDateTime{} = dt) do
    DateTime.from_naive!(dt, "Etc/UTC")
    |> to_key
  end

  def to_key(%DateTime{} = dt) do
    dt
    |> DateTime.to_unix(:millisecond)
    |> to_string
  end

  def utc_millis_to_key(millis) do
    to_string(millis)
  end

  def key_to_millis(key), do: String.to_integer(key)
  def key_to_second(key), do: trunc(String.to_integer(key) / 1000)

  def second_to_key(seconds) when is_integer(seconds) do
    seconds
    |> DateTime.from_unix!()
    |> to_key()
  end

  def key_to_datetime(key) do
    millis =
      case key do
        b when is_binary(b) -> String.to_integer(b)
        i when is_integer(i) -> i
      end

    {:ok, dt} = DateTime.from_unix(millis, :millisecond)
    DateTime.to_naive(dt)
  end

  def key_to_datetime(key, tz) do
    {:ok, dt} = DateTime.from_unix(String.to_integer(key), :millisecond)
    DateTime.shift_zone!(dt, tz) |> DateTime.to_naive(dt)
  end

  def millis_to_time(millis) do
    minutes = trunc(millis / 1000 / 60)

    remaining = millis - minutes * 1000 * 60

    %{minutes: minutes, seconds: remaining / 1000}
  end

  def time_to_label(%{minutes: minutes, seconds: seconds}) do
    f = :erlang.float_to_binary(seconds, decimals: 3)
    "#{minutes}:#{String.pad_leading(f, 6, "0")}"
  end

  def subtract(key, seconds) do
    {i, ""} = Integer.parse(key)
    to_string(i - seconds * 1000)
  end

  def now() do
    DateTime.to_unix(DateTime.now!("Etc/UTC"), :millisecond)
  end

  def to_range(
        %{
          "type" => "unix_second_range",
          "from" => from,
          "to" => to
        },
        _tz
      ) do
    from_s = DateTime.from_unix!(from, :second) |> to_key()

    to_s = DateTime.from_unix!(to, :second) |> to_key()

    {from_s, to_s}
  end
end
