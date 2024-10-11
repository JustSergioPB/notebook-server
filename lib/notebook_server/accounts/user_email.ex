defmodule NotebookServer.Accounts.UserEmail do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: NotebookServerWeb.Gettext

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
      %{} = changeset -> add_error(changeset, :email, gettext("user_email_did_not_change"))
    end
  end

  def validate(changeset, opts) do
    changeset
    |> validate_required([:email], message: gettext("field_required"))
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: gettext("user_email_invalid"))
    |> validate_length(:email, max: 160, message: gettext("max_length %{max}", max: 160))
    |> maybe_validate_unique(opts)
  end

  def maybe_validate_unique(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, NotebookServer.Repo)
      |> unique_constraint(:email, message: gettext("user_email_must_be_unique"))
    else
      changeset
    end
  end
end
