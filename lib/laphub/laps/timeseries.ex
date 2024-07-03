defmodule Laphub.Laps.Timeseries do
  require Logger
  alias Phoenix.PubSub

  def init(path) do
    File.mkdir_p!(path)
    filename = :binary.bin_to_list(path)
    Logger.info("Opening db at #{filename}")

    {:ok, db} =
      case :rocksdb.open(filename, create_if_missing: true) do
        {:ok, db} ->
          {:ok, db}

        {:error, {:db_open, e}} ->
          Logger.warning("Failed to open #{e}")
          :ok = :rocksdb.repair(filename, [])
          :rocksdb.open(filename, create_if_missing: true)
      end

    handle = {db, path}

    # TODO: This will be buggy when the owner proc dies
    me = self()

    spawn(fn ->
      ref = Process.monitor(me)

      receive do
        {:DOWN, ^ref, _, _, _reason} -> close(handle)
      end
    end)

    {:ok, handle}
  end

  def destroy_forever({path, _db} = both) do
    close(both)
    File.rm_rf!(path)
  end

  def close({db, _}), do: :rocksdb.close(db)

  defp encode(term), do: :erlang.term_to_binary(term)
  defp decode(bin), do: :erlang.binary_to_term(bin)

  def put({db, path}, key, val) when is_binary(key) do
    :rocksdb.put(db, key, encode(val), [])
    PubSub.broadcast(Laphub.InternalPubSub, path, {key, val})
  end

  def delete({db, _}, key) do
    :rocksdb.delete(db, key, [])
  end

  def subscribe(path) do
    PubSub.subscribe(Laphub.InternalPubSub, path)
  end

  def get({db, _}, key) when is_binary(key) do
    case :rocksdb.get(db, key, []) do
      {:ok, bin} -> {:ok, decode(bin)}
      other -> other
    end
  end

  def get_or({db, _}, key, default) do
    case get(db, key) do
      {:ok, value} -> value
      :not_found -> default
    end
  end

  def exists?({db, _}, key) do
    case :rocksdb.get(db, key, []) do
      {:ok, _bin} -> true
      _ -> false
    end
  end

  def stats({db, _}) do
    {:ok, memtable} = :rocksdb.get_property(db, "rocksdb.size-all-mem-tables")
    {memtable, ""} = Integer.parse(memtable)

    %{
      count: :rocksdb.count(db),
      disk_usage: 0,
      size_all_memtables: memtable
    }
  end

  defp emit({:ok, key, bin}, it), do: {[{key, decode(bin)}], it}
  defp emit({:error, :iterator_closed}, it), do: {:halt, it}
  defp emit({:error, :invalid_iterator}, it), do: {:halt, it}
  defp emit({:error, :einval}, it), do: {:halt, it}

  defp walk({db, _}, it_action, direction) do
    Stream.resource(
      fn ->
        {:ok, it} = :rocksdb.iterator(db, [])
        {it, :init}
      end,
      fn
        {it, :init} ->
          result = :rocksdb.iterator_move(it, it_action)
          emit(result, it)

        it ->
          :rocksdb.iterator_move(it, direction) |> emit(it)
      end,
      fn
        {it, :init} ->
          :rocksdb.iterator_refresh(it)
          :rocksdb.iterator_close(it)

        it ->
          :rocksdb.iterator_refresh(it)
          :rocksdb.iterator_close(it)
      end
    )
  end

  def walk_forward(db_path, from_key) do
    walk(db_path, {:seek, from_key}, :next)
  end

  def walk_backward(db_path, from_key) do
    walk(db_path, {:seek, from_key}, :prev)
  end

  def all(db_path) do
    walk(db_path, :first, :next)
  end

  def all_reversed(db_path) do
    walk(db_path, :last, :prev)
  end

  def range(db_path) do
    first_key = fn s ->
      s
      |> Stream.map(fn {k, _v} -> k end)
      |> Enum.take(1)
      |> case do
        [k] -> k
        _ -> nil
      end
    end

    min_k = first_key.(walk(db_path, :first, :next))
    max_k = first_key.(walk(db_path, :last, :prev))

    {min_k, max_k}
  end
end
