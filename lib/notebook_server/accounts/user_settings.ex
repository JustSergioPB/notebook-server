defmodule NotebookServer.Accounts.UserSettings do
  use Ecto.Schema
  import Ecto.Changeset
  alias NotebookServer.Accounts.User
  use Gettext, backend: NotebookServerWeb.Gettext

  schema "user_settings" do
    field :language, Ecto.Enum, values: [:en, :es], default: :es
    field :name, :string
    field :last_name, :string
  end

  def changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:language, :name, :last_name])
    |> User.validate_name()
    |> User.validate_last_name()
    |> User.validate_language()
  end
end
