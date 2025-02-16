# 🏎️ LapHub 🏁

Welcome to our open source racing telemetry hub software! If you find bugs [please feel free to report them][bugs]. 

## Setup

### Language dependencies
We use [asdf][asdf] for managing language dependencies for this project. If you want to use it / check it out, [here are their getting started docs][asdf-setup]. With `asdf` installed, getting the languages setup is as easy as running `$ asdf install` in the repo. Alternatively, install the versions of `erlang` and `elixir` described in this repositories [.tool-versions][tool-versions] file.

### Dev dependencies

* Run `scripts/create-postgres-user.bash` to create postgres user that local dev will user to access postgres
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
### Video
* make port sticky - so if the session stops/starts then OBS doesn't need to use a new port - registry is probably not the move here
* ideally use a token?

### CRUD
* team
  * drivers within team
* tracks



## iex

```
alias Laphub.Repo
alias Laphub.Laps.{Sesh, ActiveSesh, Timeseries}

{:ok, pid} = Repo.get(Sesh, 5) |> ActiveSesh.get_or_start



s = ActiveSesh.stream(pid, "rpm", fn ts ->
  Timeseries.all(ts)
end)
```


## TODO
* fix time selector 
