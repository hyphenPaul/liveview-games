defmodule GamesWeb.Hangman do
  use GamesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, game: Games.Hangman.new(), page_title: "Hangman")}
  end

  def handle_event("on_keyup", %{"key" => key}, %{assigns: %{game: game}} = socket) do
    case Games.Hangman.guess_letter(game, key) do
      {:ok, game} -> {:noreply, assign(socket, :game, game)}
      {:error, error_string} -> {:noreply, put_flash(socket, :error, error_string)}
    end
  end

  def handle_event("restart", _unsigned_params, socket) do
    {:noreply, assign(socket, game: Games.Hangman.new())}
  end
end
