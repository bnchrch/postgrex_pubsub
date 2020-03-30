defmodule PostgrexPubsub.Listener do
  @moduledoc """
  A macro for creating a simple listener for postgres changes
  """

  # TODO make this configurable
  @default_channel "pg_mutations"

  defmacro __using__(opts) do
    repo_module =
      opts
      |> Map.new()
      |> Map.get(:repo)

    quote do
      use GenServer
      require Logger

      @doc """
      Initialize the GenServer in the supervision tree
      """
      def child_spec(_) do
        Supervisor.Spec.worker(
          __MODULE__,
          [
            unquote(@default_channel),
            [name: __MODULE__]
          ],
          restart: :permanent
        )
      end

      @doc """
      Initialize the activity GenServer
      """
      @spec start_link([String.t()], [any]) :: {:ok, pid}
      def start_link(channel, otp_opts \\ []),
        do: GenServer.start_link(__MODULE__, channel, otp_opts)

      @doc """
      When the GenServer starts subscribe to the given topics
      """
      def init(channel) do
        Logger.debug("Starting #{__MODULE__} with channel subscription: #{channel}")
        pg_config = unquote(repo_module).config()
        {:ok, pid} = Postgrex.Notifications.start_link(pg_config)
        {:ok, ref} = Postgrex.Notifications.listen(pid, channel)
        {:ok, {pid, channel, ref}}
      end

      @doc """
      Listen for changes
      """
      def handle_info({:notification, _pid, _ref, _channel_name, payload}, _state) do
        payload
        |> Jason.decode!()
        |> handle_mutation_event()

        {:noreply, :event_handled}
      catch
        _, error ->
          Logger.error("Listener: #{__MODULE__} failed with error: #{inspect(error)}")
          {:noreply, :event_error}
      end

      def handle_info(value, _state) do
        {:noreply, :event_received}
      end
    end
  end
end
