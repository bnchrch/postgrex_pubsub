defmodule PostgrexPubsub do
  @moduledoc """
  Documentation for `PostgrexPubsub`.
  """

  @default_channel "pg_mutations"

  def get_trigger_name(table_name), do: "notify_#{table_name}_changes_trigger"

  def create_postgres_broadcast_function_sql(channel_to_broadcast_on) do
    "CREATE OR REPLACE FUNCTION broadcast_changes()
      RETURNS trigger AS $$
      DECLARE
        current_row RECORD;
      BEGIN
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
          current_row := NEW;
        ELSE
          current_row := OLD;
        END IF;
        IF (TG_OP = 'INSERT') THEN
          OLD := NEW;
        END IF;
      PERFORM pg_notify(
          '#{channel_to_broadcast_on}',
          json_build_object(
            'table', TG_TABLE_NAME,
            'type', TG_OP,
            'id', current_row.id,
            'new_row_data', row_to_json(NEW),
            'old_row_data', row_to_json(OLD)
          )::text
        );
      RETURN current_row;
      END;
      $$ LANGUAGE plpgsql;"
  end

  def create_table_mutation_trigger_sql(table_name) do
    trigger_name = get_trigger_name(table_name)
    "CREATE TRIGGER #{trigger_name}
      AFTER INSERT OR UPDATE OR DELETE
      ON #{table_name}
      FOR EACH ROW
      EXECUTE PROCEDURE broadcast_changes();"
  end

  def broadcast_mutation_for_table(table_name) do
    @default_channel
    |> create_postgres_broadcast_function_sql()
    |> Ecto.Migration.execute()

    table_name
    |> create_table_mutation_trigger_sql()
    |> Ecto.Migration.execute()
  end

  def delete_broadcast_trigger_for_table(table_name) do
    trigger_name = get_trigger_name(table_name)
    Ecto.Migration.execute "DROP TRIGGER #{trigger_name}"
  end
end
