defmodule NotebookServer.PKIs.KeyPair do
  def generate do
    private_key = X509.PrivateKey.new_rsa(4096)
    public_key = private_key |> X509.PublicKey.derive() |> X509.PublicKey.to_der()

    {private_key, public_key}
  end
end
