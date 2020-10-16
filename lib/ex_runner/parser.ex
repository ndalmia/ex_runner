defmodule ExRunner.Parser do
  @moduledoc false

  def parse(schema_type, data) when is_nil(data) do
    parse(schema_type, %{})
  end

  def parse(schema_type, data) when is_map(data) do
    Enum.reduce schema_type.__schema__(:fields), %{}, fn field, parsed_data ->
      Map.put(parsed_data, field, field_value(data, field, schema_type.__schema__(:type, field)))
    end
  end

  defp field_value(data, field, field_type) when is_tuple(field_type)  do
    info = elem(field_type, tuple_size(field_type)-1)
    cond do
      info.cardinality == :one -> parse(info.related, Map.get(data, field))
      info.cardinality == :many && is_nil(Map.get(data, field)) -> []
      info.cardinality == :many && !is_nil(Map.get(data, field)) ->
        Enum.map Map.get(data, field), fn field_value ->
          parse(info.related, field_value)
        end
    end
  end

  defp field_value(data, field, _field_type) do
    (Map.get(data, field) || Map.get(data, Atom.to_string(field)))
  end
end
