# 🏎️ LapHub 🏁

Welcome to our open source racing telemetry hub software! If you find bugs [please feel free to report them][bugs].

## Setup

### Language dependencies
We use [asdf][asdf] for managing language dependencies for this project. If you want to use it / check it out, [here are their getting started docs][asdf-setup]. With `asdf` installed, getting the languages setup is as easy as running `$ asdf install` in the repo. Alternatively, install the versions of `erlang` and `elixir` described in this repositories [.tool-versions][tool-versions] file.

### Dev dependencies

* Run `mix setup` to install and setup project dependencies

## Running the base station

In your terminal, run `iex -S mix` and then in the iex console, run:
```
LapBasestation.up(7)
```
it should print stuff


For the server, top pane, you shouldn't need to restart it, but if you do, run
`iex -S mix phx.server`

[asdf]: https://asdf-vm.com/
[asdf-setup]: https://asdf-vm.com/guide/getting-started.html
[bugs]: https://github.com/rozap/laphub/issues/new
[tool-versions]: .tool-versions




































# Laphub

## TODO
* make series toggleable
* only fetch series that are needed

## iex

```
alias Laphub.Repo
alias Laphub.Laps.{Sesh, ActiveSesh, Timeseries}

{:ok, pid} = Repo.get(Sesh, 3) |> ActiveSesh.get_or_start

s = ActiveSesh.stream(pid, fn ts ->
  Timeseries.all(ts)
end)
```
