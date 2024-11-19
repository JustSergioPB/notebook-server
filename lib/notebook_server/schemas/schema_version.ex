defmodule NotebookServer.Schemas.SchemaVersion do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: NotebookServerWeb.Gettext

  alias NotebookServer.Schemas.Schema

  schema "schema_versions" do
    field :title, :string, virtual: true
    field :raw_content, :string, virtual: true, default: "{}"

    field :description, :string
    field :platform, Ecto.Enum, values: [:web2, :web3], default: :web2
    field :status, Ecto.Enum, values: [:draft, :published, :archived], default: :draft
    field :content, :map
    field :version_number, :integer
    field :public_id, :binary_id
    belongs_to :user, NotebookServer.Accounts.User
    belongs_to :schema, NotebookServer.Schemas.Schema

    timestamps(type: :utc_datetime)
  end

  def changeset(schema_version, attrs) do
    schema_version
    |> cast(attrs, [
      :description,
      :platform,
      :status,
      :raw_content,
      :version_number,
      :user_id,
      :schema_id,
      :title
    ])
    |> Schema.validate_title()
    |> validate_description()
    |> validate_content()
    |> maybe_transform_content()
  end

  def validate_description(changeset) do
    changeset
    |> validate_length(:description,
      min: 2,
      max: 255,
      message: gettext("schema_description_length %{min} %{max}", min: 2, max: 255)
    )
  end

  def publish_changeset(schema_version) do
    change(schema_version, status: :published)
  end

  def archive_changeset(schema_version) do
    change(schema_version, status: :archived)
  end

  defp validate_content(changeset) do
    content = changeset |> get_change(:raw_content)

    changeset |> maybe_decode(content)
  end

  defp maybe_decode(changeset, content) when is_binary(content) do
    changeset =
      case Jason.decode(content) do
        {:ok, _} -> changeset
        {:error, _} -> add_error(changeset, :raw_content, gettext("invalid_json"))
      end

    changeset
  end

  defp maybe_decode(changeset, _), do: changeset

  defp maybe_transform_content(changeset) do
    raw_content = changeset |> get_change(:raw_content)
    title = changeset |> get_change(:title)
    description = changeset |> get_change(:description)

    raw_content =
      if is_binary(raw_content) do
        Jason.decode!(raw_content)
      else
        %{}
      end

    properties = %{
      "@context" => %{
        "const" => ["https://www.w3.org/ns/credentials/v2"]
      },
      "title" => %{
        "const" => title
      },
      "type" => %{
        "const" => ["VerifiableCredential"]
      },
      "issuer" => %{
        "type" => "string",
        "format" => "uri"
      },
      "credentialSubject" => %{
        "type" => "object",
        "properties" => %{
          "id" => %{
            "type" => "string",
            "pattern" => "#TODO"
          },
          "content" => raw_content
        },
        "required" => ["id", "content"]
      },
      "credentialSchema" => %{
        "type" => "object",
        "properties" => %{
          "id" => %{
            "type" => "string",
            "format" => "uri"
          },
          "type" => %{
            "const" => "JsonSchema"
          }
        },
        "required" => ["id", "type"]
      }
    }

    properties =
      if is_binary(description),
        do: Map.put(properties, "description", %{"const" => description}),
        else: properties

    content = %{
      "$schema" => "https://json-schema.org/draft/2020-12/schema",
      "title" => title,
      "type" => "object",
      "properties" => properties,
      "required" => [
        "@context",
        "title",
        "type",
        "issuer",
        "credentialSubject",
        "credentialSchema"
      ]
    }

    content =
      if is_binary(description), do: Map.put(content, "description", description), else: content

    changeset =
      if(changeset.valid?) do
        changeset
        |> put_change(:content, content)
      else
        changeset
      end

    changeset
  end

  def get_title(schema_version, schema) do
    title = schema |> Map.get(:title)
    schema_version |> Map.put(:title, title)
  end

  def get_credential_subject_content(schema_version) do
    content = schema_version.content["properties"]["credentialSubject"]["properties"]["content"]
    schema_version |> Map.put(:credential_subject_content, content)
  end

  def get_raw_content(schema_version) do
    content = schema_version.content["properties"]["credentialSubject"]["properties"]["content"]
    schema_version |> Map.put(:raw_content, Jason.encode!(content, pretty: true))
  end
end
