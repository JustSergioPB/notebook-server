defmodule NotebookServer.Accounts.UserCreate do
  use Ecto.Schema
  import Ecto.Changeset

  alias NotebookServer.Accounts.UserEmail

  schema "user_create" do
    field :name, :string
    field :last_name, :string
    field :email, :string
    field :role, Ecto.Enum, values: [:admin, :org_admin, :user]
  end

  def changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:name, :last_name, :email, :role])
    |> validate_required([
      :name,
      :last_name,
      :email,
      :role
    ])
    |> validate_length(:name, min: 3, message: "must be at least 3 characters")
    |> validate_length(:last_name, min: 3, message: "must be at least 3 characters")
    |> validate_inclusion(:role, [:admin, :org_admin, :user], message: "is not a valid role")
    |> UserEmail.validate([])
  end
end
