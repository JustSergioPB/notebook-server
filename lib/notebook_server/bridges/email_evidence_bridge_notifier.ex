defmodule NotebookServer.Bridges.EmailEvidenceBridgeNotifier do
  import Swoosh.Email

  alias NotebookServer.Mailer

  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from(
        {Application.get_env(:notebook_server, NotebookServer.Mailer)[:from],
         Application.get_env(:notebook_server, NotebookServer.Mailer)[:email]}
      )
      |> subject(subject)
      |> text_body(body)

    Mailer.deliver(email)
    |> case do
      {:ok, _} -> {:ok, email}
      {:error, error} -> {:error, error}
    end
  end

  def deliver_code(email, code) do
    deliver(email, "Email validation code", """

    ==============================

    Hi #{email},

    You can confirm your email credential request with the following code:

    #{code}

    If you didn't request an email credential with us, please ignore this.

    ==============================
    """)
  end
end
