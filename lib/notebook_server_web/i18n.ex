defmodule NotebookServerWeb.I18n do
  alias NotebookServer.Accounts
  import Plug.Conn

  @supported_locales Gettext.known_locales(NotebookServerWeb.Gettext)
  @cookie "stamp_locale"

  @spec fetch_locale(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def fetch_locale(conn, _opts) do
    locale = conn.cookies[@cookie] || get_req_header(conn, "accept-language")[0]
    assign(conn, :locale, locale)
  end

  def on_mount(:default, _params, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])
    locale = (user.language || session["locale"]) |> Atom.to_string()
    locale = check_locale(locale)
    Gettext.put_locale(NotebookServerWeb.Gettext, locale)
    {:cont, socket}
  end

  defp check_locale(locale) when locale in @supported_locales, do: locale
  defp check_locale(_), do: Gettext.get_locale(NotebookServerWeb.Gettext)
end
