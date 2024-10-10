defmodule NotebookServer.Accounts.UserPassword do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: NotebookServerWeb.Gettext

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: gettext("user_password_does_not_match"))
    |> validate(opts)
  end

  def validate(changeset, opts) do
    changeset
    |> validate_required([:password], message: gettext("field_required"))
    |> validate_length(:password,
      min: 12,
      max: 72,
      message: gettext("user_password_length %{min} %{max}", min: 12, max: 72)
    )
    |> validate_format(:password, ~r/[a-z]/,
      message: gettext("user_password_at_least_one_lower_case_character")
    )
    |> validate_format(:password, ~r/[A-Z]/,
      message: gettext("user_password_at_least_one_upper_case_character")
    )
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/,
      message: gettext("user_password_at_least_one_digit_or_punctuation_character")
    )
    |> maybe_hash(opts)
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, gettext("user_password_is_not_valid"))
    end
  end

  def maybe_hash(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid?(%NotebookServer.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid?(_, _) do
    Bcrypt.no_user_verify()
    false
  end
end
