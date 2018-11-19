# TODO skip in specs for now
return if Rails.env.test?

Rails.application.config.middleware.use OmniAuth::Builder do
  configure do |config|
    config.path_prefix = '/auth'
    config.logger = Rails.logger
  end

  begin
    # Read service provider keystore
    keystore = java.security.KeyStore.get_instance('JKS')
    encoder = java.util.Base64.get_mime_encoder(76, "\n".bytes.to_java(:byte))
    keystore.load(java.io.FileInputStream.new(ENV.fetch('UPVS_SP_KS_FILE')), ENV.fetch('UPVS_SP_KS_PASSWORD').chars.to_java(:char))
    certificate = encoder.encode_to_string(keystore.get_certificate(ENV.fetch('UPVS_SP_KS_ALIAS')).get_encoded)
    private_key = encoder.encode_to_string(keystore.get_key(ENV.fetch('UPVS_SP_KS_ALIAS'), ENV.fetch('UPVS_SP_KS_PRIVATE_PASSWORD').chars.to_java(:char)).get_encoded)
  rescue java.lang.Throwable => e
    raise "#{e.class}: #{e.message}" # TODO
  end

  # Read identity provider metadata
  idp_metadata = OneLogin::RubySaml::IdpMetadataParser.new.parse_to_hash(File.read(ENV.fetch('UPVS_IDP_METADATA')))

  # Read server setup
  protocol = Rails.application.config.force_ssl ? 'https' : 'http'
  host, port = Rails::Server::Options.new.parse!(ARGV).slice(:Host, :Port).values

  # Assemble settings
  settings = idp_metadata.merge(
    request_path: '/auth/saml/login',
    callback_path: '/auth/saml/callback',

    issuer: ENV.fetch('UPVS_SP_ISSUER'),
    assertion_consumer_service_url: "#{protocol}://#{host}:#{port}/auth/saml/callback",
    name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
    protocol_binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
    sp_name_qualifier: ENV.fetch('UPVS_SP_ISSUER'),

    certificate: certificate,
    private_key: private_key,

    security: {
      authn_requests_signed: true,
      logout_requests_signed: true,
      logout_responses_signed: true,
      want_assertions_signed: true,
      want_assertions_encrypted: true,
      want_name_id: true,
      metadata_signed: true,
      embed_sign: true,

      digest_method: XMLSecurity::Document::SHA512,
      signature_method: XMLSecurity::Document::RSA_SHA512,
    },

    double_quote_xml_attribute_values: true,
    force_authn: false,
    passive: false,
  )

  provider :saml, settings
end
