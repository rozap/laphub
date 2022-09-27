# Laphub


## iex

```
alias Laphub.Repo
alias Laphub.Laps.{Sesh, ActiveSesh, Timeseries}

{:ok, pid} = Repo.get(Sesh, 3) |> ActiveSesh.get_or_start

s = ActiveSesh.stream(pid, fn ts ->
  Timeseries.all(ts)
end)
```
