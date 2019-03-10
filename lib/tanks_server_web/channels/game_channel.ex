defmodule TanksServerWeb.GameChannel do
  use TanksServerWeb, :channel
  alias TanksServer.{ActivePlayer, PlayerTracker}

  def join("game:tanks:play:" <> game_id, %{} = _payload, socket) do
    {:ok,
      socket
      |> assign(:game_id, game_id)}
  end

  def join("game:tanks:play:" <> game_id, %{"player_id" => player_id} = _payload, socket) do
    send(self(), {:add_player, game_id, player_id})

    {:ok,
      socket
      |> assign(:player_id, player_id)
      |> assign(:game_id, game_id)}
  end

  def handle_info({:add_player, game_id, player_id}, socket) do
    # existing_players =
    #   PlayerTracker.list("active_players:#{game_id}")

    # game_ready = Enum.count(existing_players) >= 1

    # # let the existing players know about the player who just joined
    # broadcast!(socket, "player_joined", %{"player_info" => %{"id" => player_id, "x" => 150, "y" => 0}, "game_is_ready" => game_ready})

    # # gather existing players and
    # # push to the socket for each player info
    # existing_players
    # |> Enum.map(fn({id, _}) -> ActivePlayer.get_info("#{game_id}__#{id}") end)
    # |> Enum.each(fn(existing_player) -> push(socket, "player_joined", %{"player_info" => existing_player, "game_is_ready" => game_ready}) end)

    # # begin tracking the new player
    # {:ok, active_player_pid} = activeplayer.start_link(game_id, player_id)
    # playertracker.track(
    #   active_player_pid,
    #   "active_players:#{game_id}",
    #   player_id,
    #   %{}
    # )

    # {:noreply, assign(socket, :player_id, player_id)}
  end

  def terminate(_reason, %Phoenix.Socket{assigns: %{game_id: game_id, player_id: player_id}} = socket) do
    name = String.to_atom("#{game_id}__#{player_id}")
    active_player_pid = Process.whereis(name)

    PlayerTracker.untrack(active_player_pid, "active_players:#{game_id}", player_id)

    broadcast_from!(socket, "player_left", %{"id" => socket.assigns.player_id})
  end

  def terminate(_reason, _socket) do
  end


  def handle_in("list_players", _params, socket) do
    game_id = socket.assigns.game_id

    existing_players =
      PlayerTracker.list("active_players:#{game_id}")
      |> Enum.map(fn({id, _}) -> ActivePlayer.get_info("#{game_id}__#{id}") end)

    push(socket, "list_players", %{"players" => existing_players})
    {:noreply, socket}
  end

  def handle_in("add_player", %{"player_id" => player_id}, socket) do
    game_id = socket.assigns.game_id

    # begin tracking the new player
    {:ok, active_player_pid} = ActivePlayer.start_link(game_id, player_id)
    PlayerTracker.track(
      active_player_pid,
      "active_players:#{game_id}",
      player_id,
      %{}
    )

    # let the existing players know about the player who just joined
    broadcast!(socket, "player_joined", %{"player_info" => %{"id" => player_id, "x" => 150, "y" => 300}})

    {:noreply, assign(socket, :player_id, player_id)}
  end

  def handle_in("move", %{"x" => x, "y" => y, "velocity" => velocity, "barrel_rotation" => barrel_rotation}, socket) do
    player_id = socket.assigns.player_id
    game_id = socket.assigns.game_id

    ActivePlayer.update_position("#{game_id}__#{player_id}", x, y)

    broadcast_from!(socket, "move", %{id: player_id, x: x, y: y, velocity: velocity, barrel_rotation: barrel_rotation})
    {:noreply, socket}
  end

  def handle_in("fire", %{"rotation" => rotation, "power" => power, "velocity" => velocity}, socket) do
    player_id = socket.assigns.player_id
    game_id = socket.assigns.game_id

    broadcast_from!(socket, "fire", %{id: player_id, rotation: rotation, power: power, velocity: velocity})
    {:noreply, socket}
  end

  def handle_in("explode", %{"player_id" => player_id}, socket) do
    broadcast!(socket, "explode", %{id: player_id})
    {:noreply, socket}
  end
end
