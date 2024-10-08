defmodule NotebookServer.Accounts.UserSettings do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_settings" do
    field :language, Ecto.Enum, values: [:en, :es], default: :es
    field :name, :string
    field :last_name, :string
  end

  def changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:language, :name, :last_name])
    |> validate_required([:language, :name, :last_name])
    |> validate_length(:name, min: 3, message: "must be at least 3 characters")
    |> validate_length(:last_name, min: 3, message: "must be at least 3 characters")
    |> validate_inclusion(:language, [:en, :es], message: "is not a valid language")
  end
end
