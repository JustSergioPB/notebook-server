defmodule NotebookServer.PKIs.PrivateKey do
  def encrypt(private_key) do
    Plug.Crypto.encrypt(secret(), to_string(:pki), private_key, [max_age: 365 * 24 * 60 * 60])
  end

  def decrypt(cipher) do
    Plug.Crypto.decrypt(secret(), to_string(:pki), cipher)
  end

  defp secret() do
    Application.get_env(:notebook_server, NotebookServer.PKIs)[:pki_secret_key]
  end
end
