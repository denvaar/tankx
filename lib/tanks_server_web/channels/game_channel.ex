defmodule TanksServerWeb.GameChannel do
  use TanksServerWeb, :channel

  def join("game:lobby", %{"player_id" => player_id, "x" => x, "y" => y, "game_id" => game_id} = _payload, socket) do
    send(self(), {:add_player, game_id, player_id, x, y})

    {:ok,
      %{"id" => player_id, "x" => x, "y" => y},
      socket
      |> assign(:player_id, player_id)
      |> assign(:game_id, game_id)}
  end

  def terminate(_reason, socket) do
    game_id =
      socket.assigns.game_id
      |> String.to_atom()

    TanksServer.TankGame.remove_player(game_id, socket.assigns.player_id)
    broadcast_from!(socket, "player_left", %{"id" => socket.assigns.player_id})
  end

  def handle_info({:add_player, game_id, player_id, x, y}, socket) do
    TanksServer.TankGame.start_link(game_id) # could possibly already be started, but that's ok

    # let the joining player know of all the existing players
    for player <- TanksServer.TankGame.players(String.to_atom(game_id)) do
      push(
        socket,
        "player_joined",
        player
      )
    end

    # let the existing players know about the player who just joined
    TanksServer.TankGame.add_player(String.to_atom(game_id), player_id, x, y)
    broadcast_from!(socket, "player_joined", %{"id" => player_id, "x" => x, "y" => y})

    {:noreply, socket}
  end

  def handle_in("fire", %{}, socket) do
    game_id =
      socket.assigns.game_id
      |> String.to_atom()

    fire_result = TanksServer.TankGame.fire(game_id, socket.assigns.player_id)
    push(socket, "fire", %{permitted: fire_result})
    {:noreply, socket}
  end

  def handle_in("move", %{"x" => x, "y" => y}, socket) do
    game_id =
      socket.assigns.game_id
      |> String.to_atom()

    player = TanksServer.TankGame.move(game_id, socket.assigns.player_id, x, y)
    broadcast(socket, "move", player)
    {:noreply, socket}
  end
end
