defmodule PostgrexPubsub do
  @moduledoc """
  Documentation for `PostgrexPubsub`.
  """

  def default_channel, do: Application.get_env(:postgrex_pubsub, :channel) || "pg_mutations"

  def create_table_mutation_trigger_sql(table_name, trigger_name, function_name) do
    "CREATE TRIGGER #{trigger_name}
      AFTER INSERT OR UPDATE OR DELETE
      ON #{table_name}
      FOR EACH ROW
      EXECUTE PROCEDURE #{function_name}();"
  end

  def delete_trigger(trigger_name) do
    Ecto.Migration.execute("DROP TRIGGER #{trigger_name}")
  end

  defmodule PayloadStrategy do
    def function_name, do: "broadcast_payload_changes"
    def get_trigger_name(table_name), do: "notify_#{table_name}_payload_changes_trigger"

    def create_postgres_broadcast_payload_function_sql(channel_to_broadcast_on) do
      "CREATE OR REPLACE FUNCTION #{function_name()}()
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

    def broadcast_mutation_for_table(table_name) do
      PostgrexPubsub.default_channel
      |> create_postgres_broadcast_payload_function_sql()
      |> Ecto.Migration.execute()

      trigger_name = get_trigger_name(table_name)
      table_name
      |> PostgrexPubsub.create_table_mutation_trigger_sql(trigger_name, function_name())
      |> Ecto.Migration.execute()
    end

    def delete_broadcast_trigger_for_table(table_name) do
      table_name
      |> get_trigger_name()
      |> PostgrexPubsub.delete_trigger()
    end
  end

 defmodule IdStrategy do
  def function_name, do: "broadcast_id_changes"
  def get_trigger_name(table_name), do: "notify_#{table_name}_id_changes_trigger"

  def create_postgres_broadcast_id_function_sql(channel_to_broadcast_on) do
    "CREATE OR REPLACE FUNCTION #{function_name()}()
      RETURNS trigger AS $$
      DECLARE
        current_row RECORD;
      BEGIN
        IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
          current_row := NEW;
        ELSE
          current_row := OLD;
        END IF;
      PERFORM pg_notify(
          '#{channel_to_broadcast_on}',
          json_build_object(
            'table', TG_TABLE_NAME,
            'type', TG_OP,
            'id', current_row.id
          )::text
        );
      RETURN current_row;
      END;
      $$ LANGUAGE plpgsql;"
  end

  def broadcast_mutation_for_table(table_name) do
    PostgrexPubsub.default_channel
    |> create_postgres_broadcast_id_function_sql()
    |> Ecto.Migration.execute()

    trigger_name = get_trigger_name(table_name)
    table_name
    |> PostgrexPubsub.create_table_mutation_trigger_sql(trigger_name, function_name())
    |> Ecto.Migration.execute()
  end

  def delete_broadcast_trigger_for_table(table_name) do
    table_name
    |> get_trigger_name()
    |> PostgrexPubsub.delete_trigger()
  end
 end
end
