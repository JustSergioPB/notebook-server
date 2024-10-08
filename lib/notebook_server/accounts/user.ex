defmodule NotebookServer.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias NotebookServer.Accounts.UserEmail
  alias NotebookServer.Accounts.UserPassword

  schema "users" do
    field :name, :string
    field :last_name, :string
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :status, Ecto.Enum, values: [:active, :inactive], default: :active
    field :language, Ecto.Enum, values: [:en, :es], default: :es
    field :confirmed_at, :utc_datetime
    field :role, Ecto.Enum, values: [:admin, :org_admin, :user], default: :user
    belongs_to :org, NotebookServer.Orgs.Org

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs \\ %{}, opts \\ []) do
    user
    |> cast(attrs, [:name, :last_name, :email, :role, :org_id, :password])
    |> validate_required([:name, :last_name, :email, :role, :org_id, :password])
    |> UserEmail.validate(opts)
    |> UserPassword.validate(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  def deactivation_changeset(user) do
    change(user, status: :inactive)
  end

  def activation_changeset(user) do
    change(user, status: :active)
  end
end
