defmodule Laphub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Laphub.Repo,
      # Start the Telemetry supervisor
      LaphubWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Laphub.PubSub},
      # Start the Endpoint (http/https)
      LaphubWeb.Endpoint
      # Start a worker by calling: Laphub.Worker.start_link(arg)
      # {Laphub.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Laphub.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LaphubWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
