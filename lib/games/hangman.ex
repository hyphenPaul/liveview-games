defmodule Games.Hangman do
  @moduledoc """
  A game of hangman
  """

  @phrases [
    "yada yada",
    "jaws of death",
    "when the rubber hits the road",
    "raining cats and dogs",
    "go for broke",
    "on the ropes",
    "down for the count",
    "hit below the belt",
    "a dime a dozen",
    "flea market"
  ]

  defstruct phrase: [], guesses: [], matches: [], fail_count: 0, state: :playing

  @type t :: %__MODULE__{
          phrase: list(String.t()),
          guesses: list(String.t()),
          matches: list(String.t()),
          fail_count: non_neg_integer(),
          state: :playing | :won | :lost
        }

  def new(phrase \\ nil) do
    phrase = phrase || Enum.random(@phrases)

    %__MODULE__{
      phrase: phrase |> String.downcase() |> String.graphemes()
    }
    |> build_matches()
  end

  def guess_letter(%__MODULE__{phrase: phrase, guesses: guesses, state: :playing} = game, letter) do
    letter = String.downcase(letter)

    cond do
      String.length(letter) > 1 ->
        {:error, "Must guess a single letter"}

      Enum.member?(guesses, letter) ->
        {:error, "Letter already guessed"}

      !Regex.match?(~r/[a-z]/, letter) ->
        {:error, "Letter must be between A - Z"}

      Enum.member?(phrase, letter) ->
        {:ok,
         game
         |> Map.put(:guesses, game.guesses ++ [letter])
         |> build_matches()
         |> build_result()}

      true ->
        {:ok,
         game
         |> Map.put(:guesses, game.guesses ++ [letter])
         |> Map.put(:fail_count, game.fail_count + 1)
         |> build_result()}
    end
  end

  def guess_letter(game, _), do: game

  defp build_result(%__MODULE__{fail_count: 7} = game), do: %{game | state: :lost}

  defp build_result(%__MODULE__{matches: matches} = game) do
    state =
      if Enum.all?(matches, fn letter -> Regex.match?(~r/[a-z ]/, letter) end) do
        :won
      else
        :playing
      end

    %{game | state: state}
  end

  defp build_matches(%__MODULE__{phrase: phrase, guesses: guesses} = game) do
    matches =
      Enum.map(phrase, fn letter ->
        cond do
          Enum.member?(guesses, letter) -> letter
          letter == " " -> " "
          true -> "_"
        end
      end)

    %{game | matches: matches}
  end
end
