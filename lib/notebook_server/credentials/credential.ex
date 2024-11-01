defmodule NotebookServer.Credentials.Credential do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: NotebookServerWeb.Gettext

  schema "credentials" do
    field :content, :map
    field :raw_content, :any, virtual: true
    field :credential_id, :string, virtual: true
    belongs_to :issuer, NotebookServer.Accounts.User
    belongs_to :schema, NotebookServer.Schemas.Schema
    belongs_to :schema_version, NotebookServer.Schemas.SchemaVersion
    belongs_to :org, NotebookServer.Orgs.Org

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(credential, attrs, schema) do
    credential
    |> cast(attrs, [:issuer_id, :schema_id, :schema_version_id, :org_id, :content])
    |> validate_required([:issuer_id, :schema_id, :schema_version_id, :org_id, :content])
    |> validate_content(:raw_content, schema)
    |> maybe_transform_content(:raw_content, schema)
  end

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
    minimum = schema |> Map.get("minimum")
    exclusive_minimum = schema |> Map.get("exclusiveMinimum")
    maximum = schema |> Map.get("maximum")
    exclusive_maximum = schema |> Map.get("exclusiveMaximum")
    multipe_of = schema |> Map.get("multipleOf")

    changeset
    |> maybe_validate_min(field, minimum, exclusive_minimum)
    |> maybe_validate_max(field, maximum, exclusive_maximum)
    |> maybe_multiple_of(field, multipe_of)
  end

  defp validate_content(changeset, field, %{"type" => "null"}) do
    content = get_field(changeset, field)

    case content do
      nil -> changeset
      _ -> add_error(changeset, field, gettext("value_doesnt_match_null"))
    end
  end

  defp validate_content(changeset, field, %{"type" => "boolean"}) do
    content = get_field(changeset, field)

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
  end

  defp maybe_validate_format(changeset, field, "date") do
    content = get_change(changeset, field)

    case Date.from_iso8601(content) do
      {:ok, _} -> changeset
      {:error, _} -> add_error(changeset, field, gettext("invalid_date_format"))
    end
  end

  defp maybe_validate_format(changeset, field, "time") do
    content = get_change(changeset, field)

    case Time.from_iso8601(content) do
      {:ok, _} -> changeset
      {:error, _} -> add_error(changeset, field, gettext("invalid_time_format"))
    end
  end

  defp maybe_validate_format(changeset, field, "uri") do
    content = get_change(changeset, field)

    case URI.parse(content) do
      %URI{scheme: nil} -> add_error(changeset, field, gettext("invalid_uri_format_scheme"))
      %URI{host: nil} -> add_error(changeset, field, gettext("invalid_uri_format_host"))
      _ -> changeset
    end
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

  defp maybe_multiple_of(changeset, field, multiple_of)
       when is_integer(multiple_of) or is_number(multiple_of) do
    content = get_change(changeset, field)

    if rem(content, multiple_of) == 0 do
      changeset
    else
      add_error(
        changeset,
        field,
        gettext("must_be_a_multiple_of %{multiple_of}", multiple_of: multiple_of)
      )
    end
  end

  defp maybe_multiple_of(changeset, _, _), do: changeset

  defp maybe_transform_content(changeset, field, schema) do
    raw_content = changeset |> get_change(field)
    issuer_id = changeset |> get_change(:issuer_id)
    schema_id = changeset |> get_change(:schema_id)
    schema_version_id = changeset |> get_change(:schema_version_id)
    org_id = changeset |> get_change(:org_id)
    credential_id = changeset |> get_change(:credential_id)
    domain_url = Application.get_env(:notebook_server, :url)

    content = %{
      "@context" => ["https://www.w3.org/ns/credentials/v2"],
      "title" => schema.title,
      "type" => ["VerifiableCredential"],
      "issuer" => "#{domain_url}/#{org_id}/#{issuer_id}",
      "credentialSubject" => %{
        "id" => credential_id,
        "content" => raw_content
      },
      "credentialSchema" => %{
        "id" => "#{domain_url}/#{schema_id}/v#{schema_version_id}",
        "type" => "JsonSchema"
      }
    }

    description = schema |> Map.get("description")

    content =
      if is_binary(description), do: Map.put(content, "description", description), else: content

    changeset =
      if(changeset.valid?) do
        changeset
        |> put_change(:content, content)
        |> delete_change(:raw_content)
        |> delete_change(:credential_id)
      else
        changeset
      end

    changeset
  end
end
