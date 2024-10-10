defmodule NotebookServer.Accounts.UserCreate do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: NotebookServerWeb.Gettext

  alias NotebookServer.Accounts.UserEmail
  alias NotebookServer.Accounts.User

  schema "user_create" do
    field :name, :string
    field :last_name, :string
    field :email, :string
    field :role, Ecto.Enum, values: [:admin, :org_admin, :user]
  end

  def changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:name, :last_name, :email, :role])
    |> User.validate_name()
    |> User.validate_last_name()
    |> User.validate_role()
    |> UserEmail.validate([])
  end
end
