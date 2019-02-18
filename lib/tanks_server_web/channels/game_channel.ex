defmodule TanksServerWeb.GameChannel do
  use TanksServerWeb, :channel

  def join("game:lobby", %{"player_id" => player_id, "game_id" => game_id} = _payload, socket) do
    send(self(), {:add_player, game_id, player_id})

    {:ok,
      socket
      |> assign(:player_id, player_id)
      |> assign(:game_id, game_id)}
  end

  def terminate(_reason, socket) do
    game_id =
      socket.assigns.game_id
      |> String.to_atom()

    TanksServer.TankGame.remove_player(game_id, socket.assigns.player_id)
    broadcast_from!(socket, "player_left", %{"player_id" => socket.assigns.player_id})
  end

  def handle_info({:begin_game, game_id}, socket) do
    {:noreply, socket}
  end

  def handle_info({:add_player, game_id, player_id}, socket) do
    TanksServer.TankGame.start_link(game_id)
    TanksServer.TankGame.add_player(String.to_atom(game_id), player_id)
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
end
