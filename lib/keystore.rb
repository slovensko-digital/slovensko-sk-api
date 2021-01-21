# TODO remove in favor of PKCS -> replace Java Keystores with PKCS in pure OpenSSL Ruby library

class KeyStore
  Error = Class.new(StandardError)

  def initialize(file, password, type: 'JKS')
    @keystore = java.security.KeyStore.get_instance(type)
    @keystore.load(java.io.FileInputStream.new(file), password.chars.to_java(:char))
    # TODO is this a bug? file not closed!
  rescue
    raise Error
  end

  def certificate(entry)
    @keystore.get_certificate(entry)
  rescue
    raise Error
  end

  def certificate_in_base64(entry)
    encode_base64(certificate(entry))
  end

  def private_key(entry, private_password)
    @keystore.get_key(entry, private_password.chars.to_java(:char))
  rescue
    raise Error
  end

  def private_key_in_base64(entry, private_password)
    encode_base64(private_key(entry, private_password))
  end

  private

  def base64_encoder
    @base64_encoder ||= java.util.Base64.get_mime_encoder(76, "\n".bytes.to_java(:byte))
  end

  def encode_base64(object)
    base64_encoder.encode_to_string(object.get_encoded)
  end
end
