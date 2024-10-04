defmodule NotebookServer.Orgs.Org do
  use Ecto.Schema
  import Ecto.Changeset

  schema "orgs" do
    field :name, :string
    field :status, Ecto.Enum, values: [:active, :inactive], default: :active
    has_many :users, NotebookServer.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(org, attrs) do
    org
    |> cast(attrs, [:name])
    |> validate_required([:name], message: "Name is required")
    |> validate_length(:name, min: 3, message: "Name must be at least 3 characters")
  end

  def deactivation_changeset(org) do
    change(org, status: :inactive)
  end

  def activation_changeset(org) do
    change(org, status: :active)
  end
end
