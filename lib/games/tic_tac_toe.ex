defmodule Games.TicTacToe do
  @moduledoc """
  A basic tic-tac-toe game and functionality. The board is built as a grid of
  x and y values as a list of tuples [{y, x}, {y, x}...].

  {0, 0} | {1, 0} | {2, 0}
  ------------------------
  {0, 1} | {1, 1} | {2, 1}
  ------------------------
  {0, 2} | {1, 2} | {2, 2}
  """
  require Integer

  defstruct [:grid, round: 0, state: :playing, winner: nil, winning_coords: []]

  @type game_state :: :playing | :draw | {:winner, list({non_neg_integer(), non_neg_integer()}), :x | :o}
  @type t :: %__MODULE__{
          grid: map(),
          round: non_neg_integer(),
          state: game_state(),
          winner: nil | :x | :o,
          winning_coords: list({non_neg_integer(), non_neg_integer()})
        }

  def new, do: %__MODULE__{grid: base_grid()}

  @spec add_coords(__MODULE__.t(), non_neg_integer(), non_neg_integer()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def add_coords(%__MODULE__{grid: grid, round: round, state: :playing} = game, x, y) do
    case grid[{y, x}] do
      false ->
        value = if Integer.is_even(round), do: :x, else: :o
        grid = Map.put(grid, {y, x}, value)
        state = state(grid)
        winner = winner(state)
        winning_coords = winning_coords(state)

        {:ok, %{game | grid: grid, state: state, round: round + 1, winner: winner, winning_coords: winning_coords}}

      _ ->
        {:error, "Coordinates already taken"}
    end
  end

  def add_coords(_, _, _), do: {:error, "Game has ended"}

  @spec state(map()) :: game_state()
  defp state(grid) do
    reduced_coordinates =
      Enum.reduce(grid, %{:x => [], :o => [], false => []}, fn {{y, x}, value}, acc ->
        Map.put(acc, value, acc[value] ++ [{y, x}])
      end)

    x_winning_paths = winning_paths(reduced_coordinates[:x])
    o_winning_paths = winning_paths(reduced_coordinates[:o])

    cond do
      x_winning_paths != [] -> {:winner, List.flatten(x_winning_paths), :x}
      o_winning_paths != [] -> {:winner, List.flatten(o_winning_paths), :o}
      reduced_coordinates[false] == [] -> :draw
      true -> :playing
    end
  end

  @spec base_grid :: map()
  defp base_grid do
    for y <- 0..2, x <- 0..2, into: %{}, do: {{y, x}, false}
  end

  @spec winning_paths(list({non_neg_integer(), non_neg_integer()})) :: list({non_neg_integer(), non_neg_integer()})
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

  @spec winner(game_state()) :: nil | :x | :y
  def winner({:winner, _, winner}), do: winner
  def winner(_), do: nil

  @spec winning_coords(game_state()) :: list({non_neg_integer(), non_neg_integer()})
  def winning_coords({:winner, choords, _}), do: choords
  def winning_coords(_), do: []
end
