defmodule NotebookServer.Certificates.EncryptionTools do
  @aes_block_size 16
  @salt_size 16
  @iterations 100_000
  @key_size 32

  def encrypt_private_key(private_key_pem) when is_binary(private_key_pem) do
    salt = :crypto.strong_rand_bytes(@salt_size)
    iv = :crypto.strong_rand_bytes(@aes_block_size)
    key = derive_key(secret(), salt)
    padding_size = @aes_block_size - rem(byte_size(private_key_pem), @aes_block_size)
    padding = String.duplicate(<<padding_size>>, padding_size)
    encrypted = :crypto.crypto_one_time(:aes_256_cbc, key, iv, private_key_pem <> padding, true)
    salt <> iv <> encrypted
  end

  def decrypt_private_key(encrypted_private_key) do
    <<salt::binary-size(@salt_size), iv::binary-size(@aes_block_size), encrypted::binary>> =
      encrypted_private_key

    key = derive_key(secret(), salt)
    decrypt(encrypted, key, iv)
  end

  defp derive_key(password, salt) do
    :crypto.pbkdf2_hmac(:sha256, password, salt, @iterations, @key_size)
  end

  defp decrypt(ciphertext, key, iv) do
    case :crypto.crypto_one_time(:aes_256_cbc, key, iv, ciphertext, false) do
      decrypted when is_binary(decrypted) ->
        padding_size = :binary.last(decrypted)
        unpadded = binary_part(decrypted, 0, byte_size(decrypted) - padding_size)
        {:ok, unpadded}
    end
  end

  defp secret() do
    Application.get_env(:notebook_server, NotebookServer.Certificates)[:pki_secret_key]
  end
end
