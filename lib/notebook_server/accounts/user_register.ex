defmodule NotebookServer.Accounts.UserRegister do
  use Ecto.Schema
  import Ecto.Changeset

  alias NotebookServer.Orgs.Org
  alias NotebookServer.Accounts.User
  alias NotebookServer.Accounts.UserEmail
  alias NotebookServer.Accounts.UserPassword
  use Gettext, backend: NotebookServerWeb.Gettext

  schema "user_register" do
    field :name, :string
    field :last_name, :string
    field :email, :string
    field :password, :string
    field :org_name, :string
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :name, :last_name, :org_name])
    |> User.validate_name()
    |> User.validate_last_name()
    |> Org.validate_name(:org_name, validate_unique: false)
    |> UserEmail.validate(validate_email: false)
    |> UserPassword.validate(hash_password: false)
  end
end
