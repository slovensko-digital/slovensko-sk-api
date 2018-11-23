module UpvsEnvironment
  extend self

  def assertion_store
    # TODO there is also a ActiveSupport::Cache::Store::RedisStore
    @assertion_store ||= ActiveSupport::Cache::MemoryStore.new(
      namespace: 'upvs-assertions',
      size: 128.megabytes,
      compress: true,
    )
  end

  def token_authenticator
    @token_authenticator ||= TokenAuthenticator.new(
      assertion_store: assertion_store,
      private_key: OpenSSL::PKey::RSA.new(File.read(ENV.fetch('UPVS_TOKEN_PRIVATE_KEY')))
    )
  end

  def sktalk_receiver(assertion)
    SktalkReceiver.new(upvs_proxy(assertion))
  end

  def sktalk_saver(assertion)
    SktalkSaver.new(sktalk_receiver(assertion))
  end

  def upvs_properties(assertion)
    environment = case ENV.fetch('UPVS_ENV')
    when 'dev'
      {
        'upvs.eks.address' => 'https://edeskii.vyvoj.upvs.globaltel.sk/EKSService.svc',
        'upvs.ez.address' => 'https://vyvoj.upvs.globaltel.sk/ServiceBus/ServiceBusToken.svc',
        'upvs.iam.address' => 'https://authws.vyvoj.upvs.globaltel.sk/iamws17/GetIdentityService',
        'upvs.sktalk.address' => 'https://vyvoj.upvs.globaltel.sk/g2g/G2GServiceBus/ServiceSkTalk3Token.svc',
        'upvs.sts.address' => 'https://authws.vyvoj.upvs.globaltel.sk/sts/wss11x509',

        'upvs.log.file.pattern' => 'log/upvs-%d{yyyyMMdd}.log',
        'upvs.log.java.console.level' => 'INFO',

        'upvs.timeout.connection' => '30000',
        'upvs.timeout.receive' => '60000',
      }
    when 'fix'
      {
        # TODO

        'upvs.eks.address' => 'https://eschranka.upvsfixnew.gov.sk/EKSService.svc',
        'upvs.ez.address' => 'https://usr.upvsfixnew.gov.sk/ServiceBus/ServiceBusToken.svc',
        'upvs.iam.address' => '',
        'upvs.sktalk.address' => 'https://uir.upvsfixnew.gov.sk/G2GServiceBus/ServiceSkTalk3Token.svc',
        'upvs.sts.address' => 'https://iamwse.upvsfix.gov.sk:8581/sts/wss11x509',

        'upvs.log.console' => 'OFF',
        'upvs.log.file.pattern' => 'log/upvs-%d{yyyyMMdd}.log',

        'upvs.timeout.connection' => '30000',
        'upvs.timeout.receive' => '60000',
      }
    when 'prod'
      {
        # TODO

        'upvs.log.console' => 'OFF',
        'upvs.log.file' => 'OFF',
      }
    else
      raise 'Unknown environment'
    end

    security = {
      'upvs.tls.truststore.file' => ENV['UPVS_TLS_TS_FILE'],
      'upvs.tls.truststore.password' => ENV['UPVS_TLS_TS_PASSWORD'],

      'upvs.sts.keystore.file' => ENV['UPVS_STS_KS_FILE'],
      'upvs.sts.keystore.alias' => ENV['UPVS_STS_KS_ALIAS'],
      'upvs.sts.keystore.password' => ENV['UPVS_STS_KS_PASSWORD'],
      'upvs.sts.keystore.private.password' => ENV['UPVS_STS_KS_PRIVATE_PASSWORD'],

      'upvs.sts.saml.assertion' => assertion,
    }

    environment.merge(security)
  end

  # TODO remove this in favor of #upvs_proxy_cache.fetch(assertion) { ... }
  def upvs_proxy(assertion)
    UpvsProxy.new(upvs_properties(assertion))
  end

  # TODO add proxy cache like this:
  # def upvs_proxy_cache
  #   @upvs_proxy_cache ||= ...
  # end

  def authentication_settings
    return @authentication_settings if @authentication_settings

    idp_metadata = OneLogin::RubySaml::IdpMetadataParser.new.parse_to_hash(File.read(ENV.fetch('UPVS_IDP_METADATA')))
    sp_metadata = Hash.from_xml(File.read(ENV.fetch('UPVS_SP_METADATA'))).fetch('EntityDescriptor')
    keystore = KeyStore.new(ENV.fetch('UPVS_SP_KS_FILE'), ENV.fetch('UPVS_SP_KS_PASSWORD'))

    @authentication_settings ||= idp_metadata.merge(
      request_path: '/auth/saml',
      callback_path: '/auth/saml/callback',

      issuer: sp_metadata['entityID'],
      assertion_consumer_service_url: sp_metadata['SPSSODescriptor']['AssertionConsumerService'].first['Location'],
      single_logout_service_url: sp_metadata['SPSSODescriptor']['SingleLogoutService'].first['Location'],
      name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
      protocol_binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
      sp_name_qualifier: sp_metadata['entityID'],

      # TODO this somehow does not get executed, see: https://github.com/omniauth/omniauth-saml#single-logout
      # idp_slo_session_destroy: proc { |env, session| binding.pry },

      certificate: keystore.certificate(ENV.fetch('UPVS_SP_KS_ALIAS')),
      private_key: keystore.private_key(ENV.fetch('UPVS_SP_KS_ALIAS'), ENV.fetch('UPVS_SP_KS_PRIVATE_PASSWORD')),

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
  end
end
