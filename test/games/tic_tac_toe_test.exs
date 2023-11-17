defmodule Games.TicTacToeTest do
  @moduledoc false

  use ExUnit.Case

  alias Games.TicTacToe

  describe "new/0" do
    test "returns a fresh tic-tac-toe game" do
      assert result = TicTacToe.new()
      assert result.grid == for(y <- 0..2, x <- 0..2, into: %{}, do: {{y, x}, false})
      assert result.round == 0
      assert result.state == :playing
      assert result.winner == nil
    end

    test "adds players" do
      assert result = TicTacToe.new(123, 456)
      assert result.players == {{:x, 123}, {:o, 456}}
      assert result.player_turn == {:x, 123}
    end
  end

  describe "add_coords/3" do
    test "updates grid coordinates and round" do
      assert {:ok, result} = TicTacToe.add_coords(TicTacToe.new(), 2, 1)

      assert result.grid == %{
               {0, 0} => false,
               {0, 1} => false,
               {0, 2} => false,
               {1, 0} => false,
               {1, 1} => false,
               {1, 2} => :x,
               {2, 0} => false,
               {2, 1} => false,
               {2, 2} => false
             }

      assert result.round == 1
    end

    test "updates player turn and sets winner" do
      assert result = TicTacToe.new(123, 456)
      assert result.player_turn == {:x, 123}
      assert {:ok, result} = TicTacToe.add_coords(result, 0, 0)
      assert result.player_turn == {:o, 456}
      assert {:ok, result} = TicTacToe.add_coords(result, 1, 0)
      assert result.player_turn == {:x, 123}
      assert {:ok, result} = TicTacToe.add_coords(result, 0, 1)
      assert result.player_turn == {:o, 456}
      assert {:ok, result} = TicTacToe.add_coords(result, 1, 1)
      assert result.player_turn == {:x, 123}
      assert {:ok, result} = TicTacToe.add_coords(result, 0, 2)
      assert result.player_turn == nil
      assert result.winning_player == {:x, 123}
    end

    test "does not allow coords to be updated" do
      assert {:ok, result} = TicTacToe.add_coords(TicTacToe.new(), 2, 1)
      assert {:error, "Coordinates already taken"} = TicTacToe.add_coords(result, 2, 1)
    end

    test "sets a draw state" do
      # x | o | x
      # ---------
      # x | o | x
      # ---------
      # o | x | 

      grid = %{
        {0, 0} => :x,
        {0, 1} => :o,
        {0, 2} => :x,
        {1, 0} => :x,
        {1, 1} => :o,
        {1, 2} => :x,
        {2, 0} => :o,
        {2, 1} => :x,
        {2, 2} => false
      }

      ttt = %TicTacToe{grid: grid, round: 7}
      assert {:ok, result} = TicTacToe.add_coords(ttt, 2, 2)
      assert result.state == :draw
    end

    test "sets a winning state" do
      # x | o | o
      # ---------
      #   | x | 
      # ---------
      #   |   | x

      assert {:ok, result} = TicTacToe.add_coords(TicTacToe.new(), 0, 0)
      assert {:ok, result} = TicTacToe.add_coords(result, 1, 0)
      assert {:ok, result} = TicTacToe.add_coords(result, 1, 1)
      assert {:ok, result} = TicTacToe.add_coords(result, 2, 0)
      assert {:ok, result} = TicTacToe.add_coords(result, 2, 2)
      assert {:winner, winning_coords, :x} = result.state
      assert winning_coords == [{0, 0}, {1, 1}, {2, 2}]
      assert result.winner == :x
    end
  end
end
