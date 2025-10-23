defmodule Core.Server.ChatServer.State do
  alias Core.Models.User

  defstruct user: %User{},
            known_users: %{}
end
