defmodule NotebookServer.Accounts.UserEmail do
  use Ecto.Schema
  import Ecto.Changeset

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  def validate(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique(opts)
  end

  def maybe_validate_unique(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, NotebookServer.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end
end
