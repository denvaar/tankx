defmodule TanksServer.TankGame do
  use GenServer

  # Client API

  def start_link(game_id) do
    game_id = String.to_atom(game_id)

    GenServer.start_link(
      __MODULE__,
      {:ok, game_id},
      [name: game_id]
    )
  end

  def add_player(pid, player_id, x, y) do
    GenServer.call(pid, {:add_player, player_id, x, y})
  end

  def remove_player(pid, player_id) do
    GenServer.call(pid, {:remove_player, player_id})
  end

  def players(pid) do
    GenServer.call(pid, {:players})
  end

  def fire(pid, player_id) do
    GenServer.call(pid, {:fire, player_id})
  end

  def move(pid, player_id, x, y) do
    GenServer.call(pid, {:move, player_id, x, y})
  end

  # Server API

  @impl true
  def init({:ok, _game_id}) do
    game_state = %{last_turn: nil, players: []}

    {:ok, game_state}
  end

  @impl true
  def handle_call({:add_player, player_id, x, y}, _from, game_state) do
    new_player = %{id: player_id, x: x, y: y}
    {:reply, player_id, %{game_state | players: [new_player | game_state.players]}}
  end

  def handle_call({:remove_player, player_id}, _from, game_state) do
    remaining_players = Enum.reject(game_state.players, fn(player) -> player.id == player_id end)
    {:reply, player_id, %{game_state | players: remaining_players}}
  end

  def handle_call({:players}, _from, game_state) do
    {:reply, game_state.players, game_state}
  end

  def handle_call({:fire, player_id}, _from, %{last_turn: player_id} = game_state) do
    {:reply, false, game_state}
  end

  def handle_call({:fire, player_id}, _from, game_state) do
    {:reply, true, %{game_state | last_turn: player_id}}
  end

  def handle_call({:move, player_id, x, y}, _from, game_state) do
    player_index =
      game_state.players
      |> Enum.find_index(fn(p) -> p.id == player_id end)

    players =
      game_state.players
      |> List.update_at(player_index, fn(p) -> %{p | x: x, y: y} end)

    {:reply, Enum.at(game_state.players, player_index), %{game_state | players: players}}
  end
end
