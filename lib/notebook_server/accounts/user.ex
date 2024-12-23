defmodule NotebookServer.Accounts.User do
  import Ecto.Changeset

  use Ecto.Schema
  use Gettext, backend: NotebookServerWeb.Gettext

  alias NotebookServer.Accounts.UserEmail
  alias NotebookServer.Accounts.UserPassword

  schema "users" do
    field :name, :string
    field :last_name, :string
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :status, Ecto.Enum, values: [:active, :inactive, :banned], default: :active
    field :language, Ecto.Enum, values: [:en, :es], default: :es
    field :confirmed_at, :utc_datetime
    field :role, Ecto.Enum, values: [:admin, :org_admin, :issuer], default: :issuer
    field :public_id, :binary_id
    belongs_to :org, NotebookServer.Orgs.Org
    has_many :user_certificates, NotebookServer.Certificates.UserCertificate
    has_many :user_credentials, NotebookServer.Credentials.UserCredential
    has_many :schema_versions, NotebookServer.Schemas.SchemaVersion

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs \\ %{}, opts \\ []) do
    user
    |> cast(attrs, [:name, :last_name, :email, :role, :org_id, :password, :status])
    |> validate_name()
    |> validate_last_name()
    |> UserEmail.validate(opts)
    |> UserPassword.validate(opts)
    |> validate_role()
    |> validate_status()
    |> validate_language()
  end

  def validate_name(changeset) do
    changeset
    |> validate_required([:name], message: gettext("field_required"))
    |> validate_length(:name,
      min: 2,
      max: 50,
      message: gettext("user_name_length %{min} %{max}", min: 2, max: 50)
    )
  end

  def validate_last_name(changeset) do
    changeset
    |> validate_required([:last_name], message: gettext("field_required"))
    |> validate_length(:last_name,
      min: 2,
      max: 50,
      message: gettext("user_last_name_length %{min} %{max}", min: 2, max: 50)
    )
  end

  def validate_status(changeset) do
    changeset
    |> validate_inclusion(:status, [:active, :inactive, :banned],
      message: gettext("invalid_user_status")
    )
  end

  def validate_language(changeset) do
    changeset
    |> validate_inclusion(:language, [:en, :es], message: gettext("invalid_user_language"))
  end

  def validate_role(changeset) do
    changeset
    |> validate_required([:role], message: gettext("field_required"))
    |> validate_inclusion(:role, [:admin, :org_admin, :issuer],
      message: gettext("invalid_user_role")
    )
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  def settings_changeset(user, attrs) do
    user
    |> cast(attrs, [:language, :name, :last_name])
    |> validate_name()
    |> validate_last_name()
    |> validate_language()
  end

  def create_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:name, :last_name, :email, :role])
    |> validate_name()
    |> validate_last_name()
    |> validate_role()
    |> UserEmail.validate([])
  end

  def ban_changeset(user) do
    change(user, status: :banned)
  end

  def deactivation_changeset(user) do
    change(user, status: :inactive)
  end

  def activation_changeset(user) do
    change(user, status: :active)
  end

  def can_use_platform?(user) do
    user.status == :active and user.confirmed_at != nil and user.org.status == :active
  end
end
