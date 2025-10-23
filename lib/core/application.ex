defmodule Core.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cluster.Supervisor,
       [Application.get_env(:libcluster, :topologies), [name: Core.ClusterSupervisor]]},
      Core.Server.ClusterMonitor,
      Core.Server.ChatServer
    ]

    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
