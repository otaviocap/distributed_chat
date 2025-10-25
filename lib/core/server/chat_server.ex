defmodule Core.Server.ChatServer do
  alias Core.Models.User
  alias Core.Server.ChatServer.State
  require Logger
  use GenServer

  def start_link(_state) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_state) do
    Logger.info("Starting chat server for #{Node.self()}...")
    Logger.info("Please set a username to chat")

    {:ok,
     %State{
       user: %User{username: "", id: Node.self()},
       known_users: %{}
     }}
  end

  def handle_call({:get_known_users}, _from, state = %State{}) do
    {:reply, state.known_users, state}
  end

  def handle_call({:send_message, to, message}, _from, state = %State{}) do
    if String.length(state.user.username) == 0 do
      Logger.info("Before sending a message set an username")
      {:reply, :invalid_name, state}
    else
      Logger.info("#{state.user.username} (#{state.user.id}): #{message}")

      GenServer.cast(
        {__MODULE__, Map.get(state.known_users, to)},
        {:recieve_message, %{from: state.user.username, id: state.user.id, message: message}}
      )

      {:reply, nil, state}
    end
  end

  def handle_call({:set_username, username}, _from, state = %State{}) do
    cond do
      String.length(username) == 0 ->
        {:reply, :invalid_name, state}

      Map.has_key?(state.known_users, username) ->
        Logger.info("Username #{username} already registered. Please choose another one.")
        {:reply, :already_registered, state}

      true ->
        Node.list()
        |> Enum.each(
          &GenServer.cast({__MODULE__, &1}, {:broadcast_username, Node.self(), username})
        )

        {:reply, nil, update_in(state.user, &%User{&1 | username: username})}
    end
  end

  def handle_cast({:node_down, node}, state = %State{}) do
    state = remove_user_by_node(state, node)
    {:noreply, state}
  end

  def handle_cast({:recieve_message, %{from: from, id: id, message: message}}, state = %State{}) do
    Logger.info("#{from} (#{id}): #{message}")
    {:noreply, state}
  end

  def handle_cast({:broadcast_username, node, username}, state) when is_atom(node) do
    state = remove_user_by_node(state, node)

    state =
      state.known_users
      |> update_in(&Map.put(&1, username, node))

    {:noreply, state}
  end

  defp remove_user_by_node(state = %State{}, node) do
    found =
      state.known_users
      |> Enum.find(fn {_key, value} -> value == node end)

    if found do
      {username, _node} = found
      update_in(state.known_users, &Map.delete(&1, username))
    else
      state
    end
  end

  def send_message(to, message) do
    GenServer.call(__MODULE__, {:send_message, to, message})
  end

  def set_username(username) do
    GenServer.call(__MODULE__, {:set_username, username})
  end

  def get_known_users() do
    GenServer.call(__MODULE__, {:get_known_users})
  end

  def node_down(node) do
    GenServer.cast(__MODULE__, {:node_down, node})
  end
end
