defmodule TanksServer.TankGame do
  use GenServer

  # ----------
  # Client API
  # ----------

  def start_link(game_id) do
    GenServer.start_link(
      __MODULE__,
      {:ok, game_id},
      [name: String.to_atom("tank_game_#{game_id}")]
    )
  end

  def add_player(process_handle, player_name) do
    "#{process_handle}"
    |> String.to_atom()
    |> GenServer.call({:add_player, player_name})
  end

  def switch_turns(process_handle, callback) do
    "#{process_handle}"
    |> String.to_atom()
    |> GenServer.call({:switch_turns, callback})
  end

  def set_game_live(process_handle, callback) do
    "#{process_handle}"
    |> String.to_atom()
    |> GenServer.call({:update_status, :live, callback})
  end

  def set_game_over(process_handle) do
    "#{process_handle}"
    |> String.to_atom()
    |> GenServer.call({:update_status, :over})
  end

  # ----------
  # Server API
  # ----------

  @impl true
  def init({:ok, _game_id}) do
    game_state = %{
      status: :lobby,
      players: [],
      player_turn: nil,
      next_switch_ref: nil
    }

    {:ok, game_state}
  end

  @impl true
  def handle_info({:notify_turn_switch, callback}, game_state) do
    next_player = other_player(game_state)
    callback.(next_player)
    next_switch_ref = Process.send_after(self(), {:notify_turn_switch, callback}, 15_000)

    {:noreply, %{game_state | player_turn: next_player, next_switch_ref: next_switch_ref}}
  end

  def handle_info({:cancel_timer, _, _}, game_state) do
    {:noreply, game_state}
  end

  @impl true
  def handle_call({:add_player, player_name}, _from, game_state) do
    new_game_state = %{game_state | players: [player_name | game_state[:players]]}
    {:reply, {:ok, new_game_state}, new_game_state}
  end

  def handle_call({:update_status, :over}, _from, game_state) do
    cancel_next_turn(game_state[:next_switch_ref])
    new_game_state = %{game_state | status: :over, next_switch_ref: nil}
    {:reply, {:ok, new_game_state}, new_game_state}
  end

  def handle_call({:update_status, :live, callback}, _from, game_state) do
    new_game_state = %{toggle_player_turn(game_state, callback) | status: :live}
    {:reply, {:ok, new_game_state}, new_game_state}
  end

  def handle_call({:switch_turns, callback}, _from, game_state) do
    new_game_state = toggle_player_turn(game_state, callback)
    {:reply, {:ok, new_game_state}, new_game_state}
  end



  defp toggle_player_turn(game_state, callback) do
    cancel_next_turn(game_state[:next_switch_ref])
    next_player = other_player(game_state)
    next_switch_ref = Process.send_after(self(), {:notify_turn_switch, callback}, 15_000)
    %{game_state | player_turn: next_player, next_switch_ref: next_switch_ref}
  end


  defp cancel_next_turn(nil) do
    # do nothing
  end

  defp cancel_next_turn(process_ref) do
    Process.cancel_timer(process_ref, async: true, info: true)
  end

  defp other_player(game_state) do
    game_state[:players]
    |> Enum.filter(fn p -> p != game_state[:player_turn] end)
    |> Enum.at(0)
  end
end
