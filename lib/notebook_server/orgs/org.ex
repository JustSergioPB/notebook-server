defmodule NotebookServer.Orgs.Org do
  use Ecto.Schema
  use Gettext, backend: NotebookServerWeb.Gettext
  import Ecto.Changeset

  @status [:active, :inactive, :banned]

  schema "orgs" do
    field :name, :string
    field :email, :string
    field :status, Ecto.Enum, values: @status, default: :inactive
    field :public_id, :binary_id
    has_many :users, NotebookServer.Accounts.User
    has_many :bridges, NotebookServer.Bridges.Bridge
    has_many :org_certificates, NotebookServer.Certificates.OrgCertificate
    has_many :user_certificates, NotebookServer.Certificates.UserCertificate
    has_many :user_credentials, NotebookServer.Credentials.UserCredential
    has_many :org_credentials, NotebookServer.Credentials.OrgCredential
    has_many :schemas, NotebookServer.Schemas.Schema

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(org, attrs, opts \\ []) do
    include_user? = Keyword.get(opts, :user, false)

    org
    |> cast(attrs, [:name, :email, :status])
    |> validate_required([:name, :email])
    |> validate_length(:name, min: 2, max: 50)
    |> unsafe_validate_unique(:name, NotebookServer.Repo)
    |> unique_constraint(:name)
    |> validate_length(:email, min: 2)
    |> unsafe_validate_unique(:email, NotebookServer.Repo)
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_inclusion(:status, @status)
    |> maybe_cast_user(include_user?)
  end

  def maybe_cast_user(changeset, include_user?) when include_user? == false, do: changeset

  def maybe_cast_user(changeset, _) do
    changeset |> cast_assoc(:users, required: true)
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
end
