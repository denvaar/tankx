defmodule TanksServerWeb.GameChannel do
  use TanksServerWeb, :channel
  alias TanksServer.{ActivePlayer, PlayerTracker, TankGame}

  def join("game:tanks:play:" <> game_id, %{} = _payload, socket) do
    TankGame.start_link(game_id)
    {:ok,
      socket
      |> assign(:game_id, game_id)}
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

    broadcast!(socket, "list_players", %{"players" => existing_players})
    {:noreply, socket}
  end

  def handle_in("add_player", %{"player_id" => player_id}, socket) do
    game_id = socket.assigns.game_id

    # get list of players to determine player index
    existing_players =
      PlayerTracker.list("active_players:#{game_id}")
    player_index = if Enum.count(existing_players) > 0, do: 2, else: 1

    # begin tracking the new player
    with {:ok, active_player_pid} <- ActivePlayer.start_link(game_id, player_id, player_index) do
      PlayerTracker.track(
        active_player_pid,
        "active_players:#{game_id}",
        player_id,
        %{}
      )

      TankGame.add_player("tank_game_#{game_id}", player_id)
      if player_index == 2 do
        TankGame.set_game_live(
          "tank_game_#{game_id}",
          fn (next_player) -> broadcast!(socket, "turn_time_up", %{turn: next_player}) end
        )
      end
    end

    players =
      PlayerTracker.list("active_players:#{game_id}")
      |> Enum.map(fn({id, _}) -> ActivePlayer.get_info("#{game_id}__#{id}") end)

    # let the existing players know about the player who just joined
    broadcast!(socket, "player_joined", %{"players" => players})

    {:noreply, assign(socket, :player_id, player_id)}
  end

  def handle_in("move", %{"x" => x, "y" => y, "velocity" => velocity, "barrel_rotation" => barrel_rotation}, socket) do
    player_id = socket.assigns.player_id
    game_id = socket.assigns.game_id

    ActivePlayer.update_position("#{game_id}__#{player_id}", x, y)

    broadcast_from!(socket, "move", %{id: player_id, x: x, y: y, velocity: velocity, barrel_rotation: barrel_rotation})
    {:noreply, socket}
  end

  def handle_in("fire", %{"rotation" => rotation, "power" => power}, socket) do
    player_id = socket.assigns.player_id

    broadcast!(socket, "fire", %{id: player_id, rotation: rotation, power: power})
    {:noreply, socket}
  end

  def handle_in("explode", %{"player_id" => player_id}, socket) do
    game_id = socket.assigns.game_id
    _game_state = TankGame.set_game_over("tank_game_#{game_id}")
    broadcast!(socket, "explode", %{id: player_id})
    {:noreply, socket}
  end

  def handle_in("switch_player_turn", _params, socket) do
    game_id = socket.assigns.game_id

    broadcast_turn_switch =
      fn (next_player) -> broadcast!(socket, "turn_time_up", %{turn: next_player}) end

    {:ok, game_state} = TankGame.switch_turns("tank_game_#{game_id}", broadcast_turn_switch)

    broadcast_turn_switch.(game_state[:player_turn])
    {:noreply, socket}
  end

  def handle_in("restart_game", _params, socket) do
    game_id = socket.assigns.game_id

    broadcast_turn_switch =
      fn (next_player) -> broadcast!(socket, "turn_time_up", %{turn: next_player}) end

    {:ok, game_state} = TankGame.set_game_live("tank_game_#{game_id}", broadcast_turn_switch)

    broadcast!(socket, "restart_game", %{})
    {:noreply, socket}
  end
end
