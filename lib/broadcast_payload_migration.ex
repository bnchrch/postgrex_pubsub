defmodule PostgrexPubsub.BroadcastPayloadMigration do
  @moduledoc """
  A macro for applying mutation broadcast triggers to tables
  """
  defmacro __using__(opts) do
    table_name =
      opts
      |> Map.new()
      |> Map.get(:table_name)

    quote do
      use Ecto.Migration

      def up do
        PostgrexPubsub.PayloadStrategy.broadcast_mutation_for_table(unquote(table_name))
      end

      def down do
        PostgrexPubsub.PayloadStrategy.delete_broadcast_trigger_for_table(unquote(table_name))
      end
    end
  end
end
