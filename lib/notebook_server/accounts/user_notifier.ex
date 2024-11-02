defmodule NotebookServer.Accounts.UserNotifier do
  import Swoosh.Email

  alias NotebookServer.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    IO.inspect("================================")
    IO.inspect(Application.get_env(:notebook_server, NotebookServer.Mailer)[:api_key])
    IO.inspect(Application.get_env(:notebook_server, NotebookServer.Mailer)[:domain])
    IO.inspect(Application.get_env(:notebook_server, NotebookServer.Mailer)[:from])
    IO.inspect(Application.get_env(:notebook_server, NotebookServer.Mailer)[:email])
    IO.inspect("================================")

    email =
      new()
      |> to(recipient)
      |> from(
        {Application.get_env(:notebook_server, NotebookServer.Mailer)[:from],
         Application.get_env(:notebook_server, NotebookServer.Mailer)[:email]}
      )
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirmation instructions", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset password instructions", """

    ==============================

    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
