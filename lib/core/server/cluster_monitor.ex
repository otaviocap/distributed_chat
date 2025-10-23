defmodule Core.Server.ClusterMonitor do
  require Logger
  alias Core.Server.ChatServer
  use GenServer

  def start_link(_state) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_state) do
    :net_kernel.monitor_nodes(true)

    {:ok, {}}
  end

  def handle_info({:nodeup, node}, _state) do
    Logger.info("Node #{node} is up")
    {:noreply, {}}
  end

  def handle_info({:nodedown, node}, _state) do
    Logger.info("Node #{node} is down")
    ChatServer.node_down(node)

    {:noreply, {}}
  end
end
