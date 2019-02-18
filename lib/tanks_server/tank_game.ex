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

  def add_player(pid, player_id) do
    GenServer.call(pid, {:add_player, player_id})
  end

  def remove_player(pid, player_id) do
    GenServer.call(pid, {:remove_player, player_id})
  end

  def fire(pid, player_id) do
    GenServer.call(pid, {:fire, player_id})
  end

  # Server API

  @impl true
  def init({:ok, _game_id}) do
    game_state = %{last_turn: nil, players: []}

    {:ok, game_state}
  end

  @impl true
  def handle_call({:add_player, player_id}, _from, game_state) do
    {:reply, player_id, %{game_state | players: [player_id | game_state.players]}}
  end

  def handle_call({:remove_player, player_id}, _from, game_state) do
    remaining_players = Enum.reject(game_state.players, fn(player) -> player == player_id end)
    {:reply, player_id, %{game_state | players: remaining_players}}
  end

  def handle_call({:fire, player_id}, _from, %{last_turn: player_id} = game_state) do
    {:reply, false, game_state}
  end

  def handle_call({:fire, player_id}, _from, game_state) do
    {:reply, true, %{game_state | last_turn: player_id}}
  end
end
