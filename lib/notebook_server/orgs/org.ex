defmodule NotebookServer.Orgs.Org do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: NotebookServerWeb.Gettext

  schema "orgs" do
    field :name, :string
    field :status, Ecto.Enum, values: [:active, :inactive, :banned], default: :active
    field :level, Ecto.Enum, values: [:root, :intermediate], default: :intermediate
    has_many :users, NotebookServer.Accounts.User
    has_many :user_certificates, NotebookServer.PKIs.UserCertificate
    has_many :schemas, NotebookServer.Schemas.Schema
    has_many :issued_credentials, NotebookServer.Credentials.Credential

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(org, attrs) do
    org
    |> cast(attrs, [:name, :level])
    |> validate_name(:name, validate_unique: true)
  end

  def deactivation_changeset(org) do
    change(org, status: :inactive)
  end

  def activation_changeset(org) do
    change(org, status: :active)
  end

  def ban_changeset(org) do
    change(org, status: :banned)
  end

  def validate_name(changeset, field, opts \\ []) do
    changeset
    |> validate_required([field], message: gettext("org_name_required"))
    |> validate_length(field,
      min: 2,
      max: 50,
      message: gettext("org_name_length %{min} %{max}", min: 2, max: 50)
    )
    |> maybe_validate_unique(opts)
  end

  defp maybe_validate_unique(changeset, opts) do
    if Keyword.get(opts, :validate_unique, true) do
      changeset
      |> unsafe_validate_unique(:name, NotebookServer.Repo)
      |> unique_constraint(:name, message: gettext("org_name_must_be_unique"))
    else
      changeset
    end
  end
end
