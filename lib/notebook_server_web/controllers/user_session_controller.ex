defmodule NotebookServerWeb.UserSessionController do
  use NotebookServerWeb, :controller

  alias NotebookServer.Accounts
  alias NotebookServerWeb.UserAuth
  use Gettext, backend: NotebookServerWeb.Gettext

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, gettext("user_register_success"))
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/settings")
    |> create(params, gettext("user_password_updated_success"))
  end

  def create(conn, params) do
    conn
    |> put_session(:user_return_to, ~p"/dashboard")
    |> create(params, gettext("user_login_success"))
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, gettext("user_login_error"))
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, gettext("user_logout_success"))
    |> UserAuth.log_out_user()
  end
end
