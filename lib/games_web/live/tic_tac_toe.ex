defmodule GamesWeb.TicTacToe do
  use GamesWeb, :live_view

  alias Games.Presence

  @game_topic "tictactoe"
  @game_topic_all "#{@game_topic}:all"

  def render(assigns) do
    ~H"""
    <%= if assigns[:game] do %>
      <%= if @game.state == :playing do %>
        <%= if @is_turn do %>
          <p>Click a square to add an <%= @current_symbol %></p>
        <% else %>
          <p>Waiting for opponent</p>
        <% end %>
      <% end %>
      <div class="mx-auto w-80 h-80 bg-black mb-10">
        <div class="grid grid-cols-3 grid-row-3 h-full gap-1">
          <button
            :for={{{y, x}, value} <- @game.grid}
            class="block text-center bg-white"
            phx-click="add"
            phx-value-x={x}
            phx-value-y={y}
            data-value={value}
            data-winner={Enum.member?(@game.winning_coords, {y, x})}
          >
          </button>
        </div>
      </div>

      <%= if @game.state != :playing do %>
        <div class="flex flex-col items-center">
          <%= if @game.state == :draw do %>
            <p class="uppercase text-center font-bold mb-10">It's a draw!</p>
          <% else %>
            <p class="uppercase text-center font-bold mb-10"><%= "#{elem(@game.state, 2)} won!" %></p>
          <% end %>

          <button
            class="text-center bg-sky-700 rounded p-1.5 align-center text-white font-bold uppercase"
            phx-click="rematch"
          >
            Rematch
          </button>

          <button class="text-center bg-sky-700 rounded p-1.5 align-center text-white font-bold uppercase" phx-click="quit">
            Quit
          </button>
        </div>
      <% end %>
    <% else %>
      <h2>Choose a player:</h2>
      <ul>
        <li :for={user <- @users} phx-value-user-id={user.id} phx-click="request-game"><%= user.email %></li>
      </ul>

      <%= if assigns[:game_request] do %>
        <p><%= @game_request.email %> wants to play Tic Tac Toe!!</p>
        <ul>
          <li phx-click="accept-request">Yes</li>
          <li phx-click="reject-request">No</li>
        </ul>
      <% end %>
    <% end %>
    """
  end

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    subscribe(current_user.id)

    Presence.track_topic_for_user(@game_topic_all, current_user)

    {:ok,
     assign(socket,
       users: [],
       page_title: "Tic Tac Toe"
     )}
  end

  def handle_event(
        "add",
        %{"x" => x, "y" => y},
        %{assigns: %{game: game, current_player_id: current_player_id}} = socket
      ) do
    if current_player_id == socket.assigns.current_user.id do
      case Games.TicTacToe.add_coords(game, String.to_integer(x), String.to_integer(y)) do
        {:ok, game} ->
          broadcast(game)
          {:noreply, assign(socket, game: game)}

        {:error, _} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("rematch", _unsigned_params, socket) do
    game = Games.TicTacToe.new(socket.assigns.game)
    broadcast(game)
    {:noreply, socket_from_game(socket, game)}
  end

  def handle_event("quit", _unsigned_params, socket) do
    game = socket.assigns.game
    current_id = socket.assigns.current_user.id

    opponent_user_id =
      case game.players do
        {{:x, ^current_id}, {:o, user_id}} -> user_id
        {{:x, user_id}, {:o, ^current_id}} -> user_id
      end

    unsubscribe(game)
    socket = clean_socket(socket)

    Phoenix.PubSub.broadcast(
      Games.PubSub,
      user_topic(opponent_user_id),
      # TODO: This should be a struct
      {__MODULE__, %{quit: %{game: game}}}
    )

    {:noreply, socket}
  end

  def handle_event("request-game", %{"user-id" => opponent_user_id}, socket) do
    Phoenix.PubSub.broadcast(
      Games.PubSub,
      user_topic(opponent_user_id),
      # TODO: This should be a struct
      {__MODULE__, %{game_request: %{user_id: socket.assigns.current_user.id}}}
    )

    {:noreply, socket}
  end

  def handle_event("accept-request", _, socket) do
    opponent_user_id = socket.assigns.game_request.id
    game = Games.TicTacToe.new(socket.assigns.current_user.id, opponent_user_id)
    subscribe_game(game)

    Phoenix.PubSub.broadcast(
      Games.PubSub,
      user_topic(opponent_user_id),
      # TODO: This should be a struct
      {__MODULE__, %{game_request_accepted: %{game: game}}}
    )

    socket = socket |> assign(:game_request, nil) |> socket_from_game(game)
    {:noreply, socket}
  end

  def handle_event("reject-request", _, socket) do
    opponent_user_id = socket.assigns.game_request.id

    Phoenix.PubSub.broadcast(
      Games.PubSub,
      user_topic(opponent_user_id),
      # TODO: This should be a struct
      {__MODULE__, %{game_request_rejected: %{user: socket.assigns.current_user}}}
    )

    {:noreply, assign(socket, :game_request, nil)}
  end

  def socket_from_game(socket, game) do
    {current_symbol, current_player_id, is_turn} =
      case game do
        %{player_turn: nil} -> {false, false, false}
        %{player_turn: {symbol, id}} -> {symbol, id, id == socket.assigns.current_user.id}
      end

    socket
    |> assign(:game, game)
    |> assign(:is_turn, is_turn)
    |> assign(:current_symbol, current_symbol)
    |> assign(:current_player_id, current_player_id)
  end

  def clean_socket(socket) do
    socket
    |> assign(:game, nil)
    |> assign(:is_turn, nil)
    |> assign(:current_symbol, nil)
    |> assign(:current_player_id, nil)
  end

  def broadcast(game) do
    Phoenix.PubSub.broadcast(Games.PubSub, game_topic(game), {__MODULE__, game})
  end

  # Handle all game avents
  def handle_info({__MODULE__, %Games.TicTacToe{} = game}, socket) do
    {:noreply, socket_from_game(socket, game)}
  end

  def handle_info({__MODULE__, %{quit: %{game: _game}}}, socket) do
    {:noreply, clean_socket(socket)}
  end

  def handle_info({__MODULE__, %{game_request_rejected: %{user: user}}}, socket) do
    {:noreply, put_flash(socket, :info, "#{user.email} doesn't want to play right now")}
  end

  def handle_info({__MODULE__, %{game_request_accepted: %{game: game}}}, socket) do
    subscribe_game(game)
    {:noreply, socket_from_game(socket, game)}
  end

  def handle_info({__MODULE__, %{game_request: %{user_id: user_id}}}, socket) do
    opponent = Games.Accounts.get_user!(user_id) |> Map.take([:id, :email])
    {:noreply, assign(socket, :game_request, opponent)}
  end

  ##################################################
  # Presence handling
  ##################################################

  def handle_info({{Presence, :all}, presences}, socket) do
    users = available_users(presences, socket.assigns.current_user.id)
    {:noreply, assign(socket, :users, users)}
  end

  def handle_info({{Presence, :joins}, _joins}, socket), do: {:noreply, socket}
  def handle_info({{Presence, :leaves}, _joins}, socket), do: {:noreply, socket}

  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, socket}
  end

  def subscribe(user_id) do
    Phoenix.PubSub.subscribe(Games.PubSub, @game_topic_all)
    Phoenix.PubSub.subscribe(Games.PubSub, user_topic(user_id))
  end

  def subscribe_game(%Games.TicTacToe{} = game) do
    Phoenix.PubSub.subscribe(Games.PubSub, game_topic(game))
  end

  def unsubscribe(%Games.TicTacToe{} = game) do
    Phoenix.PubSub.unsubscribe(Games.PubSub, game_topic(game))
  end

  defp user_topic(key), do: "#{@game_topic}:user:#{key}"
  defp game_topic(%Games.TicTacToe{id: id}), do: "#{@game_topic}:game:#{id}"

  defp available_users(presences, current_user_id) do
    Enum.reject(current_users(presences), &(&1.id == current_user_id))
  end

  defp current_users(presences) do
    Enum.map(presences, fn {id, [%{email: email} | _]} ->
      %{id: String.to_integer(id), email: email}
    end)
  end
end
