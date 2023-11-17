defmodule Games.Presence do
  use Phoenix.Presence,
    otp_app: :games,
    pubsub_server: Games.PubSub,
    presence: __MODULE__

  def init(_opts), do: {:ok, %{}}

  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    Phoenix.PubSub.broadcast(Games.PubSub, topic, {{__MODULE__, :all}, presences})
    Phoenix.PubSub.broadcast(Games.PubSub, topic, {{__MODULE__, :joins}, joins})
    Phoenix.PubSub.broadcast(Games.PubSub, topic, {{__MODULE__, :leaves}, leaves})

    {:ok, state}
  end

  def track_topic_for_user(topic, %{id: id, email: email}) do
    track(self(), topic, id, %{email: email})
  end
end
