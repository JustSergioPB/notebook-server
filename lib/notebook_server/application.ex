defmodule NotebookServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NotebookServerWeb.Telemetry,
      NotebookServer.Repo,
      {DNSCluster, query: Application.get_env(:notebook_server, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: NotebookServer.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: NotebookServer.Finch},
      # Start a worker by calling: NotebookServer.Worker.start_link(arg)
      # {NotebookServer.Worker, arg},
      # Start to serve requests, typically the last entry
      NotebookServerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: NotebookServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NotebookServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
