defmodule Laphub.Application do
  use Application

  @impl true
  def start(_type, _args) do
    Laphub.Laps.ActiveSesh.create()

    children = [
      # Start the Ecto repository
      Laphub.Repo,
      # Start the Telemetry supervisor
      LaphubWeb.Telemetry,
      # Start the PubSub system
      Supervisor.child_spec({Phoenix.PubSub, name: Laphub.PubSub}, id: :endpoint_pubsub),
      Supervisor.child_spec({Phoenix.PubSub, name: Laphub.InternalPubSub}, id: :internal_pubsub),

      Registry.child_spec([
        keys: :unique,
        name: Laphub.Video.VideoServer.TcpServerRegistry
      ]),
      # Start the Endpoint (http/https)
      LaphubWeb.Endpoint,


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
