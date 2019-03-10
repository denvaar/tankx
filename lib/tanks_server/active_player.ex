defmodule TanksServer.ActivePlayer do
  use GenServer

  # ----------
  # Client API
  # ----------

  def start_link(game_id, player_id) do
    GenServer.start_link(
      __MODULE__,
      {:ok, game_id, player_id},
      [name: String.to_atom("#{game_id}__#{player_id}")]
    )
  end

  def update_position(process_handle, x, y) do
    "#{process_handle}"
    |> String.to_atom()
    |> GenServer.call({:update_position, x, y})
  end

  def get_info(process_handle) do
    "#{process_handle}"
    |> String.to_atom()
    |> GenServer.call({:get_info})
  end

  # ----------
  # Server API
  # ----------

  @impl true
  def init({:ok, game_id, player_id}) do
    player_info = get_or_create_player(game_id, player_id)
    {:ok, player_info}
  end

  @impl true
  def handle_call({:update_position, x, y}, _from, player_info) do
    new_player_info = %{player_info | x: x, y: y}
    {:reply, {:ok, new_player_info}, new_player_info}
  end

  def handle_call({:get_info}, _from, player_info) do
    {:reply, player_info, player_info}
  end

  # TODO: Move to another module
  defp get_or_create_player(game_id, player_id) do
    random_x = Enum.random(20..400)
    %{id: player_id, game_id: game_id, x: random_x, y: 300} # pick arbitrary numbers for now
  end
end
