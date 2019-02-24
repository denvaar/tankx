defmodule TanksServer.PlayerTracker do
  @behaviour Phoenix.Tracker

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def start_link(opts) do
    opts = Keyword.merge([name: __MODULE__], opts)
    Phoenix.Tracker.start_link(__MODULE__, opts, opts)
  end

  def init(opts) do
    server = Keyword.fetch!(opts, :pubsub_server)
    {:ok, %{pubsub_server: server, node_name: Phoenix.PubSub.node_name(server)}}
  end

  def handle_diff(diff, state) do
    for {topic, {joins, leaves}} <- diff do
      for {key, meta} <- joins do
        IO.puts "presence join: key \"#{key}\" with meta #{inspect meta}"
        msg = {:join, key, meta}
        Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
      end
      for {key, meta} <- leaves do
        IO.puts "presence leave: key \"#{key}\" with meta #{inspect meta}"
        msg = {:leave, key, meta}
        Phoenix.PubSub.direct_broadcast!(state.node_name, state.pubsub_server, topic, msg)
      end
    end
    {:ok, state}
  end
end
