defmodule Games.HangmanTest do
  use ExUnit.Case

  alias Games.Hangman

  describe "new/1" do
    test "returns a game with a phrase populated" do
      assert result = %Hangman{} = Hangman.new()
      assert Enum.count(result.phrase) > 0
      assert Enum.all?(result.phrase, fn letter -> Regex.match?(~r/[a-z ]/, letter) end)
    end

    test "returns a game with with matches populated" do
      assert result = %Hangman{} = Hangman.new()
      assert Enum.count(result.phrase) == Enum.count(result.matches)
      assert Enum.all?(result.matches, fn letter -> Regex.match?(~r/[_ ]/, letter) end)
    end

    test "manually adds phrase" do
      assert result = %Hangman{} = Hangman.new("foo bar")
      assert result.phrase == String.graphemes("foo bar")
    end
  end

  describe "guess_letter/2" do
    test "detects correct letter guess" do
      assert result = %Hangman{} = Hangman.new("foo bar")
      assert {:ok, result} = Hangman.guess_letter(result, "o")
      assert result.fail_count == 0
      assert result.guesses == ["o"]
      assert result.state == :playing
      assert result.matches == ["_", "o", "o", " ", "_", "_", "_"]
    end

    test "detects incorrect letter guess" do
      assert result = %Hangman{} = Hangman.new("foo bar")
      assert {:ok, result} = Hangman.guess_letter(result, "z")
      assert result.fail_count == 1
      assert result.guesses == ["z"]
      assert result.state == :playing
      assert result.matches == ["_", "_", "_", " ", "_", "_", "_"]
    end

    test "returns error if guess is not a letter" do
      assert result = %Hangman{} = Hangman.new()
      assert {:error, "Letter must be between A - Z"} = Hangman.guess_letter(result, "1")
      assert {:error, "Letter must be between A - Z"} = Hangman.guess_letter(result, "]")
      assert {:error, "Letter must be between A - Z"} = Hangman.guess_letter(result, "")
    end

    test "returns error if guess multiple letters are guessed" do
      assert result = %Hangman{} = Hangman.new()
      assert {:error, "Must guess a single letter"} = Hangman.guess_letter(result, "abc")
    end

    test "game lost if fail count totals 7" do
      assert result = %Hangman{} = Hangman.new("foo bar")
      assert {:ok, result} = Hangman.guess_letter(result, "z")
      assert {:ok, result} = Hangman.guess_letter(result, "c")
      assert {:ok, result} = Hangman.guess_letter(result, "d")
      assert {:ok, result} = Hangman.guess_letter(result, "e")
      assert {:ok, result} = Hangman.guess_letter(result, "g")
      assert {:ok, result} = Hangman.guess_letter(result, "h")
      assert {:ok, result} = Hangman.guess_letter(result, "i")
      assert result.fail_count == 7
      assert result.guesses == ["z", "c", "d", "e", "g", "h", "i"]
      assert result.state == :lost
      assert result.matches == ["_", "_", "_", " ", "_", "_", "_"]
    end

    test "game won if correct phrase is guessed" do
      assert result = %Hangman{} = Hangman.new("foo bar")
      assert {:ok, result} = Hangman.guess_letter(result, "a")
      assert {:ok, result} = Hangman.guess_letter(result, "b")
      assert {:ok, result} = Hangman.guess_letter(result, "c")
      assert {:ok, result} = Hangman.guess_letter(result, "d")
      assert {:ok, result} = Hangman.guess_letter(result, "e")
      assert {:ok, result} = Hangman.guess_letter(result, "f")
      assert {:ok, result} = Hangman.guess_letter(result, "o")
      assert {:ok, result} = Hangman.guess_letter(result, "r")
      assert result.fail_count == 3
      assert result.guesses == ["a", "b", "c", "d", "e", "f", "o", "r"]
      assert result.state == :won
      assert result.matches == ["f", "o", "o", " ", "b", "a", "r"]
    end
  end
end
