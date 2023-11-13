defmodule GamesWeb.TicTacToe do
  use GamesWeb, :live_view

  require Integer

  def mount(_params, _session, socket) do
    {:ok, refresh_game(socket)}
  end

  def handle_event("add", %{"x" => x, "y" => y}, %{assigns: %{game_state: :playing}} = socket) do
    round = socket.assigns.round
    grid =  socket.assigns.grid
    x = String.to_integer(x)
    y = String.to_integer(y)
    value = if Integer.is_even(socket.assigns.round), do: "x", else: "o"
    
    socket =
      case grid[{y, x}] do
        false ->
          grid = Map.put(grid, {y, x}, value)

          socket
          |> assign(:round, round + 1)
          |> assign(:grid, grid)
          |> assign(:game_state, game_state(grid))

        _ ->
          socket
      end


    {:noreply, socket} 
  end

  def handle_event("add", _unsigned_params, socket), do: {:noreply, socket}

  def handle_event("restart", _unsigned_params, socket), do: {:noreply, refresh_game(socket)}

  defp game_state(grid) do
    reduced_coordinates = Enum.reduce(grid, %{"x" => [], "o" => [], false => []}, fn {{y, x}, value}, acc ->
      Map.put(acc, value, acc[value] ++ [{y, x}])
    end)

    x_winning_paths = winning_paths(reduced_coordinates["x"])
    o_winning_paths = winning_paths(reduced_coordinates["o"])

    cond do
      x_winning_paths != [] -> {:winner, List.flatten(x_winning_paths), "x"}
      o_winning_paths != [] -> {:winner, List.flatten(o_winning_paths), "o"}
      reduced_coordinates[false] == [] -> :draw
      true -> :playing
    end
  end

  defp winning_paths(coordinates) do
    win_grid = [
      [{0, 0}, {0, 1}, {0, 2}],
      [{1, 0}, {1, 1}, {1, 2}],
      [{2, 0}, {2, 1}, {2, 2}],
      [{0, 0}, {1, 0}, {2, 0}],
      [{0, 1}, {1, 1}, {2, 1}],
      [{0, 2}, {1, 2}, {2, 2}],
      [{0, 0}, {1, 1}, {2, 2}],
      [{0, 2}, {1, 1}, {2, 0}]
    ]

    Enum.filter(win_grid, fn winning_coordinates ->
      Enum.all?(winning_coordinates, fn x -> Enum.member?(coordinates, x) end)
    end)
  end

  @spec refresh_game(Pheonix.LiveView.Socket.t()) :: Pheonix.LiveView.Socket.t()
  defp refresh_game(socket) do
    grid = for y <- 0..2, x <- 0..2, into: %{}, do: {{y, x}, false}
    assign(socket, grid: grid, round: 0, game_state: :playing, page_title: "Tic Tac Toe")
  end
end
