defmodule NotebookServer.Credentials.Schema do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: NotebookServerWeb.Gettext

  schema "schemas" do
    field :title, :string
    field :description, :string
    field :platform, Ecto.Enum, values: [:web2, :web3], default: :web2
    field :status, Ecto.Enum, values: [:draft, :published, :archived], default: :draft
    field :credential_subject, :map, default: %{}
    belongs_to :org, NotebookServer.Orgs.Org
    belongs_to :user, NotebookServer.Accounts.User
    belongs_to :replaces, NotebookServer.Credentials.Schema

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(schema, attrs) do
    attrs =
      with true <- is_binary(attrs["credential_subject"]),
           {:ok, decoded_value} <- Jason.decode(attrs["credential_subject"]) do
        Map.put(attrs, "credential_subject", decoded_value)
      else
        _ -> attrs
      end

    schema
    |> cast(attrs, [:credential_subject, :org_id, :user_id])
    |> validate_title()
    |> validate_description()
  end

  def validate_title(changeset) do
    changeset
    |> validate_required([:title], message: gettext("field_required"))
    |> validate_length(:title,
      min: 2,
      max: 50,
      message: gettext("schema_title_length %{min} %{max}", min: 2, max: 50)
    )
  end

  def validate_description(changeset) do
    changeset
    |> validate_required([:description], message: gettext("field_required"))
    |> validate_length(:description,
      min: 2,
      max: 255,
      message: gettext("schema_description_length %{min} %{max}", min: 2, max: 255)
    )
  end
end
