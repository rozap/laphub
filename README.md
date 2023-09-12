# To restart basestation
in bash, run `iex -S mix` and then in the iex console, run:
```
LapBasestation.up(7)
```
it should print stuff


For the server, top pane, you shouldn't need to restart it, but if you do, run
`iex -S mix phx.server`







































# Laphub

## TODO
* make series toggleable
* only fetch series that are needed

## iex

```
alias Laphub.Repo
alias Laphub.Laps.{Sesh, ActiveSesh, Timeseries}

{:ok, pid} = Repo.get(Sesh, 5) |> ActiveSesh.get_or_start



s = ActiveSesh.stream(pid, "rpm", fn ts ->
  Timeseries.all(ts)
end)
```
