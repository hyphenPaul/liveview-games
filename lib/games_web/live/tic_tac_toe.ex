defmodule GamesWeb.TicTacToe do
  use GamesWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, game: Games.TicTacToe.new(), page_title: "Tic Tac Toe")}
  end

  def handle_event("add", %{"x" => x, "y" => y}, %{assigns: %{game: game}} = socket) do
    case Games.TicTacToe.add_coords(game, String.to_integer(x), String.to_integer(y)) do
      {:ok, game} -> {:noreply, assign(socket, game: game)}
      {:error, _} -> {:noreply, socket}
    end
  end

  def handle_event("restart", _unsigned_params, socket), do: {:noreply, assign(socket, game: Games.TicTacToe.new())}
end
