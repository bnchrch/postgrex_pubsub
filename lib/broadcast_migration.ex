defmodule PostgrexPubsub.BroadcastMigration do
  @moduledoc """
  """
  defmacro __using__(opts) do
    table_name =
      opts
      |> Map.new()
      |> Map.get(:table_name)

    quote do
      use Ecto.Migration
      def up do
        PostgrexPubsub.broadcast_mutation_for_table(unquote(table_name))
      end

      def down do
        PostgrexPubsub.delete_broadcast_trigger_for_table(unquote(table_name))
      end
    end
  end
end
