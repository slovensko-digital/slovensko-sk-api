module UpvsEnvironment

  # assertion on behalf of another subject expires in 20 minutes,
  # access via underlying technical account expires in 120 minutes

  PROXY_MAX_EXP_IN = 120.minutes

  extend self

  def eform_service
    EformService.new(upvs_proxy(assertion: nil))
  end

  def sktalk_receiver(assertion:)
    SktalkReceiver.new(upvs_proxy(assertion: assertion))
  end

  def properties(assertion:)
    environment = case ENV.fetch('UPVS_ENV')
    when 'dev'
      {
        'upvs.eks.address' => 'https://edeskii.vyvoj.upvs.globaltel.sk/EKSService.svc',
        'upvs.ez.address' => 'https://vyvoj.upvs.globaltel.sk/ServiceBus/ServiceBusToken.svc',
        'upvs.iam.address' => 'https://authws.vyvoj.upvs.globaltel.sk/iamws17/GetIdentityService',
        'upvs.sktalk.address' => 'https://vyvoj.upvs.globaltel.sk/g2g/G2GServiceBus/ServiceSkTalk3Token.svc',
        'upvs.sts.address' => 'https://authws.vyvoj.upvs.globaltel.sk/sts/wss11x509',

        'upvs.logger' => 'STDOUT',
      }
    when 'fix'
      {
        'upvs.eks.address' => 'https://eschranka.upvsfixnew.gov.sk/EKSService.svc',
        'upvs.ez.address' => 'https://usr.upvsfixnew.gov.sk/ServiceBus/ServiceBusToken.svc',
        'upvs.iam.address' => 'https://iamwse.upvsfix.gov.sk:7017/iamws17/GetIdentityService',
        'upvs.sktalk.address' => 'https://uir.upvsfixnew.gov.sk/G2GServiceBus/ServiceSkTalk3Token.svc',
        'upvs.sts.address' => 'https://iamwse.upvsfix.gov.sk:8581/sts/wss11x509',

        'upvs.logger' => 'STDOUT',
      }
    when 'prod'
      {
        'upvs.eks.address' => 'https://eschranka1.slovensko.sk/EKSService.svc',
        'upvs.ez.address' => 'https://usr.slovensko.sk/ServiceBus/ServiceBusToken.svc',
        'upvs.iam.address' => 'https://iamwse.slovensko.sk:7017/iamws17/GetIdentityService',
        'upvs.sktalk.address' => 'https://uir.slovensko.sk/G2GServiceBus/ServiceSkTalk3Token.svc',
        'upvs.sts.address' => 'https://iamwse.slovensko.sk:8581/sts/wss11x509',

        'upvs.logger' => 'NULL',
      }
    else
      raise 'Unknown environment'
    end

    # disable logger outside of test environment
    environment['upvs.logger'] = 'NULL' if Rails.env.test?

    # set timeout properties
    environment['upvs.timeout.connection'] = 30000
    environment['upvs.timeout.receive'] = 60000

    # set security properties
    security = {
      'upvs.tls.truststore.file' => ENV['UPVS_TLS_TS_FILE'],
      'upvs.tls.truststore.password' => ENV['UPVS_TLS_TS_PASSWORD'],

      'upvs.sts.keystore.file' => ENV['UPVS_STS_KS_FILE'],
      'upvs.sts.keystore.alias' => ENV['UPVS_STS_KS_ALIAS'],
      'upvs.sts.keystore.password' => ENV['UPVS_STS_KS_PASSWORD'],
      'upvs.sts.keystore.private.password' => ENV['UPVS_STS_KS_PRIVATE_PASSWORD'],
    }

    # try going on behalf of another subject
    security['upvs.sts.saml.assertion'] = assertion if assertion.present?

    environment.merge(security)
  end

  def upvs_proxy(assertion:)
    UpvsProxy.new(properties(assertion: assertion))

    # properties = properties(assertion: assertion)
    # initializes_in = 30.seconds
    #
    # if assertion
    #   conditions = REXML::XPath.first(assertion, '//saml:Assertion/saml:Conditions')
    #   expires_in = Time.parse(conditions.attributes['NotOnOrAfter']) - Time.now.to_f - initializes_in
    #   raise ArgumentError, 'Expired assertion' if expires_in.negative?
    # else
    #   expires_in = 2.hours - initializes_in
    # end
    #
    # upvs_proxy_cache.fetch(properties, expires_in: expires_in, race_condition_ttl: initializes_in) do
    #   UpvsProxy.new(properties)
    # end
  end

  # def upvs_proxy_cache
  #   @upvs_proxy_cache ||= ActiveSupport::Cache::MemoryStore.new(
  #     namespace: 'upvs-proxies',
  #     size: 128.megabytes,
  #     compress: false,
  #   )
  # end

  def sso_support?
    ENV.fetch('UPVS_SSO_SUPPORT', true) != 'false'
  end

  def sso_settings
    # TODO remove the next line to support live UPVS specs, need to figure out how to bring /security into CI first
    return {} if Rails.env.test?

    return @sso_settings if @sso_settings

    idp_metadata = OneLogin::RubySaml::IdpMetadataParser.new.parse_to_hash(File.read(ENV.fetch('UPVS_IDP_METADATA_FILE')))
    sp_metadata = Hash.from_xml(File.read(ENV.fetch('UPVS_SP_METADATA_FILE'))).fetch('EntityDescriptor')
    keystore = KeyStore.new(ENV.fetch('UPVS_SP_KS_FILE'), ENV.fetch('UPVS_SP_KS_PASSWORD'))

    @sso_settings ||= idp_metadata.merge(
      request_path: '/auth/saml',
      callback_path: '/auth/saml/callback',

      issuer: sp_metadata['entityID'],
      assertion_consumer_service_url: sp_metadata['SPSSODescriptor']['AssertionConsumerService'].first['Location'],
      single_logout_service_url: sp_metadata['SPSSODescriptor']['SingleLogoutService'].first['Location'],
      name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
      protocol_binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
      sp_name_qualifier: sp_metadata['entityID'],
      idp_name_qualifier: idp_metadata[:idp_entity_id],

      # TODO this gets called on IDP initiated logout, we need to invalidate SAML assertion here! removing assertion actually invalidates OBO token which is the desired effect here (cover it in specs)
      idp_slo_session_destroy: proc { |env, session| },

      certificate: keystore.certificate_in_base64(ENV.fetch('UPVS_SP_KS_ALIAS')),
      private_key: keystore.private_key_in_base64(ENV.fetch('UPVS_SP_KS_ALIAS'), ENV.fetch('UPVS_SP_KS_PRIVATE_PASSWORD')),

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
