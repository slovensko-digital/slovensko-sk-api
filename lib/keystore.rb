class KeyStore
  Error = Class.new(StandardError)

  def initialize(file, password, type: 'JKS')
    @keystore = java.security.KeyStore.get_instance(type)
    @keystore.load(java.io.FileInputStream.new(file), password.chars.to_java(:char))
  rescue
    raise Error
  end

  def certificate(entry)
    encoder.encode_to_string(@keystore.get_certificate(entry).get_encoded)
  rescue
    raise Error
  end

  def private_key(entry, private_password)
    encoder.encode_to_string(@keystore.get_key(entry, private_password.chars.to_java(:char)).get_encoded)
  rescue
    raise Error
  end

  private

  def encoder
    @encoder ||= java.util.Base64.get_mime_encoder(76, "\n".bytes.to_java(:byte))
  end
end
