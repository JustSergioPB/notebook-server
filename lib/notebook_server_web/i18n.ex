defmodule NotebookServerWeb.I18n do
  import Plug.Conn

  @supported_locales Gettext.known_locales(NotebookServerWeb.Gettext)
  @cookie "stamp_locale"

  @spec fetch_locale(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def fetch_locale(conn, _opts) do
    accept_language = get_req_header(conn, "accept-language") |> Enum.at(0)
    user = conn.assigns.current_user

    locale =
      if is_nil(user),
        do: conn.cookies[@cookie],
        else: user.language |> Atom.to_string()

    locale =
      if is_nil(locale),
        do: accept_language,
        else: locale

    conn
    |> put_resp_cookie(@cookie, locale, max_age: 365 * 24 * 60 * 60)
    |> put_session(:locale, locale)
    |> assign(:locale, locale)
  end

  def on_mount(:default, _params, session, socket) do
    locale = check_locale(session["locale"])

    Gettext.put_locale(NotebookServerWeb.Gettext, locale)
    {:cont, socket}
  end

  defp check_locale(locale) when locale in @supported_locales, do: locale
  defp check_locale(_), do: Gettext.get_locale(NotebookServerWeb.Gettext)
end
