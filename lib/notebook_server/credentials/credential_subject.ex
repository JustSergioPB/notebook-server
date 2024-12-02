defmodule NotebookServer.Credentials.CredentialSubject do
  import Ecto.Changeset
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :id, :string
    field :content, :string
  end

  def changeset(credential_subject, attrs \\ %{}) do
    credential_subject
    |> cast(attrs, [:id, :content])
    |> validate_required([:id, :content])
  end
end

"""
defp validate_content(changeset, field, %{"const" => const}) do
    content = changeset |> get_change(field)

    changeset =
      if content != const do
        add_error(changeset, field, gettext("value_doesnt_match_constant"))
      else
        changeset
      end

    changeset
  end

  defp validate_content(changeset, field, %{"enum" => enum}) when is_list(enum) do
    content = changeset |> get_change(field)

    changeset =
      if content not in enum do
        add_error(changeset, field, gettext("value_doesnt_match_option"))
      else
        changeset
      end

    changeset
  end

  defp validate_content(changeset, field, %{"type" => "string"} = schema) do
    max_length = schema |> Map.get("maxLength")
    min_length = schema |> Map.get("minLength")
    pattern = schema |> Map.get("pattern")
    format = schema |> Map.get("format")
    # encoding = schema |> Map.get("encoding")
    # content_media_type = schema |> Map.get("contentMediaType")

    changeset
    |> maybe_validate_min_length(field, min_length)
    |> maybe_validate_max_length(field, max_length)
    |> maybe_validate_pattern(field, pattern)
    |> maybe_validate_format(field, format)
  end

  defp validate_content(changeset, field, %{"type" => type} = schema)
       when type in ["integer", "number"] do
    content = changeset |> get_change(field) |> cast_content(schema)

    minimum = schema |> Map.get("minimum")
    exclusive_minimum = schema |> Map.get("exclusiveMinimum")
    maximum = schema |> Map.get("maximum")
    exclusive_maximum = schema |> Map.get("exclusiveMaximum")
    multipe_of = schema |> Map.get("multipleOf")

    changeset
    |> put_change(field, content)
    |> maybe_validate_min(field, minimum, exclusive_minimum)
    |> maybe_validate_max(field, maximum, exclusive_maximum)
    |> maybe_multiple_of(field, multipe_of, schema)
  end

  defp validate_content(changeset, field, %{"type" => "null"}) do
    content = get_field(changeset, field)

    case content do
      nil -> changeset
      _ -> add_error(changeset, field, gettext("value_doesnt_match_null"))
    end

    changeset
  end

  defp validate_content(changeset, field, %{"type" => "boolean"} = schema) do
    content = get_field(changeset, field) |> cast_content(schema)

    changeset =
      if is_boolean(content) do
        changeset
      else
        add_error(changeset, field, gettext("value_doesnt_match_boolean"))
      end

    changeset
  end

  defp maybe_validate_max_length(changeset, field, max_length) when is_integer(max_length) do
    changeset |> validate_length(field, max: max_length)
  end

  defp maybe_validate_max_length(changeset, _, _), do: changeset

  defp maybe_validate_min_length(changeset, field, min_length) when is_integer(min_length) do
    changeset |> validate_length(field, min: min_length)
  end

  defp maybe_validate_min_length(changeset, _, _), do: changeset

  defp maybe_validate_pattern(changeset, field, pattern) when is_binary(pattern) do
    changeset |> validate_format(field, Regex.compile!(pattern))
  end

  defp maybe_validate_pattern(changeset, _, _), do: changeset

  defp maybe_validate_format(changeset, field, "email") do
    changeset
    |> validate_format(field, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/,
      message: gettext("invalid_email_format")
    )
  end

  defp maybe_validate_format(changeset, field, "date-time") do
    content = get_change(changeset, field)

    case DateTime.from_iso8601(content) do
      {:ok, _, _} -> changeset
      {:error, _} -> add_error(changeset, field, gettext("invalid_datetime_format"))
    end

    changeset
  end

  defp maybe_validate_format(changeset, field, "date") do
    content = get_change(changeset, field)

    case Date.from_iso8601(content) do
      {:ok, _} -> changeset
      {:error, _} -> add_error(changeset, field, gettext("invalid_date_format"))
    end

    changeset
  end

  defp maybe_validate_format(changeset, field, "time") do
    content = get_change(changeset, field)

    case Time.from_iso8601(content) do
      {:ok, _} -> changeset
      {:error, _} -> add_error(changeset, field, gettext("invalid_time_format"))
    end

    changeset
  end

  defp maybe_validate_format(changeset, field, "uri") do
    content = get_change(changeset, field)

    case URI.parse(content) do
      %URI{scheme: nil} -> add_error(changeset, field, gettext("invalid_uri_format_scheme"))
      %URI{host: nil} -> add_error(changeset, field, gettext("invalid_uri_format_host"))
      _ -> changeset
    end

    changeset
  end

  defp maybe_validate_format(changeset, _, _), do: changeset

  defp maybe_validate_min(changeset, field, _, exclusive_min) when is_integer(exclusive_min) do
    changeset |> validate_number(field, greater_than: exclusive_min)
  end

  defp maybe_validate_min(changeset, field, min, _) when is_integer(min) do
    changeset |> validate_number(field, greater_than_or_equal_to: min)
  end

  defp maybe_validate_min(changeset, _, _, _), do: changeset

  defp maybe_validate_max(changeset, field, _, exclusive_max) when is_integer(exclusive_max) do
    changeset |> validate_number(field, less_than: exclusive_max)
  end

  defp maybe_validate_max(changeset, field, max, _) when is_integer(max) do
    changeset |> validate_number(field, less_than_or_equal_to: max)
  end

  defp maybe_validate_max(changeset, _, _, _), do: changeset

  defp maybe_multiple_of(changeset, field, multiple_of, schema)
       when is_integer(multiple_of) or is_number(multiple_of) do
    content = get_change(changeset, field) |> cast_content(schema)

    # TODO add support for float numbers
    if rem(content, multiple_of) == 0 do
      changeset
    else
      add_error(
        changeset,
        field,
        gettext("must_be_a_multiple_of %{multiple_of}", multiple_of: multiple_of)
      )
    end

    changeset
  end

  defp maybe_multiple_of(changeset, _, _, _), do: changeset

  defp cast_content(content, %{"type" => "boolean"}) do
    converted =
      cond do
        content == "true" -> true
        content == "false" -> false
        true -> "invalid"
      end

    converted
  end

  defp cast_content(content, %{"type" => "integer"}) do
    converted =
      if is_binary(content) do
        content |> String.to_integer()
      else
        0
      end

    converted
  end

  defp cast_content(content, %{"type" => "number"}) do
    converted =
      if is_binary(content) do
        content |> String.to_float()
      else
        0.0
      end

    converted
  end

  defp cast_content(content, _), do: content
"""
