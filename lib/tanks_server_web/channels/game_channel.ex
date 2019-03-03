defmodule TanksServerWeb.GameChannel do
  use TanksServerWeb, :channel
  alias TanksServer.{ActivePlayer, PlayerTracker}

  def join("game:tanks:play:" <> game_id, %{"player_id" => player_id} = _payload, socket) do
    send(self(), {:add_player, game_id, player_id})

    {:ok,
      socket
      |> assign(:player_id, player_id)
      |> assign(:game_id, game_id)}
  end

  def handle_info({:add_player, game_id, player_id}, socket) do
    # let the existing players know about the player who just joined
    broadcast!(socket, "player_joined", %{"id" => player_id, "x" => 150, "y" => 0})

    # gather existing players and
    # push to the socket for each player info
    PlayerTracker.list("active_players:#{game_id}")
    |> Enum.map(fn({id, _}) -> ActivePlayer.get_info("#{game_id}__#{id}") end)
    |> Enum.each(fn(existing_player) -> push(socket, "player_joined", existing_player) end)

    # begin tracking the new player
    {:ok, active_player_pid} = ActivePlayer.start_link(game_id, player_id)
    PlayerTracker.track(
      active_player_pid,
      "active_players:#{game_id}",
      player_id,
      %{}
    )

    {:noreply, socket}
  end

  def terminate(_reason, socket) do
    game_id = socket.assigns.game_id
    player_id = socket.assigns.player_id
    name = String.to_atom("#{game_id}__#{player_id}")
    active_player_pid = Process.whereis(name)

    PlayerTracker.untrack(active_player_pid, "active_players:#{game_id}", player_id)

    broadcast_from!(socket, "player_left", %{"id" => socket.assigns.player_id})
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
