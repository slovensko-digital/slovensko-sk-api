module UpvsEnvironment

  # assertion on behalf of another subject expires in 20 minutes,
  # access via underlying technical account expires in 120 minutes

  PROXY_MAX_EXP_IN = 120.minutes

  extend self

  # TODO replace **args with ... when on ruby 2.7
  def cep_signer(**args)
    CepSigner.new(upvs_proxy(**args))
  end

  def edesk_service(**args)
    EdeskService.new(upvs_proxy(**args))
  end

  def eform_service(**args)
    EformService.new(upvs_proxy(**args))
  end

  def iam_repository(**args)
    IamRepository.new(upvs_proxy(**args))
  end

  def sktalk_receiver(**args)
    SktalkReceiver.new(upvs_proxy(**args))
  end

  def usr_service(**args)
    UsrService.new(upvs_proxy(**args))
  end

  def create_subject(sub, cin:)
    # TODO it may be possible to use PKCS instead of JKS -> then drop keytool (Java Keystore) dependency form entire project including UPVS library -> replace it with PKCS in pure OpenSSL Ruby library

    safe_capture %W(
      keytool
      -genkeypair
      -alias #{sub}
      -keyalg RSA
      -keysize 2048
      -sigalg sha512WithRSA
      -dname CN=ico-#{cin}
      -validity 730
      -keystore #{sts_keystore_file(sub)}.pkcs12
      -storepass #{generate_pass(:ks, sub)}
    )

    # TODO this is just a hotfix we should really switch to PKCS12

    safe_capture %W(
      keytool
      -importkeystore
      -srckeystore #{sts_keystore_file(sub)}.pkcs12
      -srcstoretype pkcs12
      -srcalias #{sub}
      -srcstorepass #{generate_pass(:ks, sub)}
      -srckeypass #{generate_pass(:ks, sub)}
      -destkeystore #{sts_keystore_file(sub)}
      -deststoretype jks
      -deststorepass #{generate_pass(:ks, sub)}
      -destalias #{sub}
      -destkeypass #{generate_pass(:pk, sub)}
    )
  ensure
    File.delete(sts_keystore_file(sub) + '.pkcs12')
  end

  def delete_subject(sub)
    File.delete(sts_keystore_file(sub))
  end

  def subjects
    Dir[Rails.root.join('security', 'sts', "*_#{Upvs.env}.keystore")].map { |f| File.basename(f, '.*').rpartition('_').first }
  end

  def subject(sub)
    certificate = safe_capture %W(
      keytool
      -export
      -rfc
      -alias #{sub}
      -keystore #{sts_keystore_file(sub)}
      -storepass #{generate_pass(:ks, sub)}
    )

    attributes = safe_capture('openssl x509 -subject -enddate -fingerprint -noout -sha256', stdin_data: certificate)
    attributes = attributes.lines(chomp: true).map { |r| r.split('=', 2).last }

    {
      certificate: certificate.partition(/\n?Warning:/).first,
      subject: attributes[0].remove(%r{ */?CN *= *}),
      not_after: Time.parse(attributes[1]).in_time_zone,
      fingerprint: attributes[2].remove(':').downcase,
    }
  end

  def subject?(sub)
    File.exist?(sts_keystore_file(sub))
  end

  def upvs_properties(sub:, obo: nil)
    environment = case Upvs.env
    when 'dev'
      {
        'upvs.eks.address' => 'https://edeskii.vyvoj.upvs.globaltel.sk/EKSService.svc',
        'upvs.ez.address' => 'https://vyvoj.upvs.globaltel.sk/ServiceBus/ServiceBusToken.svc',
        'upvs.iam.address' => 'https://authws.vyvoj.upvs.globaltel.sk/iamws17/GetIdentityService',
        'upvs.sktalk.address' => 'https://vyvoj.upvs.globaltel.sk/g2g/G2GServiceBus/ServiceSkTalk3Token.svc',
        'upvs.sts.address' => 'https://authws.vyvoj.upvs.globaltel.sk/sts/wss11x509',
      }
    when 'fix'
      {
        'upvs.eks.address' => 'https://eschranka.upvsfixnew.gov.sk/EKSService.svc',
        'upvs.ez.address' => 'https://usr.upvsfixnew.gov.sk/ServiceBus/ServiceBusToken.svc',
        'upvs.iam.address' => 'https://iamwse.upvsfix.gov.sk:7017/iamws17/GetIdentityService',
        'upvs.sktalk.address' => 'https://uir.upvsfixnew.gov.sk/G2GServiceBus/ServiceSkTalk3Token.svc',
        'upvs.sts.address' => 'https://iamwse.upvsfix.gov.sk:8581/sts/wss11x509',
      }
    when 'prod'
      {
        'upvs.eks.address' => 'https://eschranka1.slovensko.sk/EKSService.svc',
        'upvs.ez.address' => 'https://usr.slovensko.sk/ServiceBus/ServiceBusToken.svc',
        'upvs.iam.address' => 'https://iamwse.slovensko.sk:7017/iamws17/GetIdentityService',
        'upvs.sktalk.address' => 'https://uir.slovensko.sk/G2GServiceBus/ServiceSkTalk3Token.svc',
        'upvs.sts.address' => 'https://iamwse.slovensko.sk:8581/sts/wss11x509',
      }
    else
      raise 'Unknown environment'
    end

    level = 'info'

    # disable logger in production by default
    level = 'off' if Upvs.env.prod?

    # disable logger in tests by default
    level = 'off' if Rails.env.test?

    # set logger properties
    environment['upvs.log.level'] = ENV.fetch('UPVS_LOG_LEVEL', level)

    # set timeout properties
    environment['upvs.timeout.connection'] = 60_000
    environment['upvs.timeout.receive'] = 120_000

    # set security properties
    security = {
      'upvs.tls.truststore.file' => tls_truststore_file,
      'upvs.tls.truststore.pass' => 'password',

      'upvs.sts.keystore.file' => sts_keystore_file(sub),
      'upvs.sts.keystore.pass' => generate_pass(:ks, sub),
      'upvs.sts.keystore.private.alias' => sub,
      'upvs.sts.keystore.private.pass' => generate_pass(:pk, sub),
    }

    # try going on behalf of another subject
    security['upvs.sts.obo'] = obo if obo.present?

    environment.merge(security)
  end

  # TODO remove in favor of #upvs_properties
  alias :properties :upvs_properties

  def upvs_proxy(**args)
    upvs_properties = upvs_properties(**args)
    upvs_proxy_cache.get(upvs_properties, -> { UpvsProxy.new(upvs_properties) })
  end

  # TODO consider cleaning up the cache automatically, see https://github.com/google/guava/wiki/CachesExplained#when-does-cleanup-happen
  # TODO or consider invalidating entries after entry-specific expiration via scheduled executor, see https://github.com/google/guava/wiki/CachesExplained#explicit-removals
  # if assertion
  #   conditions = REXML::XPath.first(assertion, '//saml:Assertion/saml:Conditions')
  #   expires_in = Time.parse(conditions.attributes['NotOnOrAfter']) - Time.now.to_f
  #   raise ArgumentError, 'Expired assertion' if expires_in.negative?
  # else
  #   expires_in = PROXY_MAX_EXP_IN
  # end

  def upvs_proxy_cache
    @upvs_proxy_cache ||= com.google.common.cache.CacheBuilder.new_builder
      .expire_after_write(PROXY_MAX_EXP_IN.to_i, java.util.concurrent.TimeUnit::SECONDS)
      .ticker(Class.new(com.google.common.base.Ticker) { define_method(:read) { Time.now.to_f * 10 ** 9 }}.new)
      .soft_values.build
  end

  def obo_support?
    @obo_support ||= ENV.key?('SSO_PROXY_SUBJECT')
  end

  def sso_support?
    @sso_support ||= ENV.key?('SSO_SP_SUBJECT')
  end

  def sso_settings
    # TODO remove the next line to support live UPVS specs, need to figure out how to bring /security into CI first
    return {} if Rails.env.test?

    return @sso_settings if @sso_settings

    idp_metadata = OneLogin::RubySaml::IdpMetadataParser.new.parse_to_hash(File.read(sso_metadata_file('upvs')))
    sp_subject = ENV.fetch('SSO_SP_SUBJECT')
    sp_metadata = Hash.from_xml(File.read(sso_metadata_file(sp_subject))).fetch('EntityDescriptor')
    # TODO is there a reason for SP sign cert to be in JKS file? (move it to PEM file under security/sso); remove lib/keystore.rb
    sp_keystore = KeyStore.new(sso_keystore_file(sp_subject), generate_pass(:ks, sp_subject))

    @sso_settings ||= idp_metadata.merge(
      request_path: '/auth/saml',
      callback_path: '/auth/saml/callback',

      issuer: sp_metadata['entityID'],
      assertion_consumer_service_url: sp_metadata['SPSSODescriptor']['AssertionConsumerService'].first['Location'],
      single_logout_service_url: sp_metadata['SPSSODescriptor']['SingleLogoutService'].first['Location'],
      idp_sso_target_url: idp_metadata[:idp_sso_service_url],
      idp_slo_target_url: idp_metadata[:idp_slo_service_url],
      name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient',
      protocol_binding: 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
      sp_name_qualifier: sp_metadata['entityID'],
      idp_name_qualifier: idp_metadata[:idp_entity_id],

      # TODO this gets called on IDP initiated logout, we need to invalidate SAML assertion here! removing assertion actually invalidates OBO token which is the desired effect here (cover it in specs)
      idp_slo_session_destroy: proc { |env, session| },

      certificate: sp_keystore.certificate_in_base64(sp_subject),
      private_key: sp_keystore.private_key_in_base64(sp_subject, generate_pass(:pk, sp_subject)),

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

  def sso_proxy_subject
    @sso_proxy_subject ||= ENV.fetch('SSO_PROXY_SUBJECT')
  end

  private

  def sso_metadata_file(sub)
    Rails.root.join('security', 'sso', "#{sub}_#{Upvs.env}.metadata.xml").to_s
  end

  def sso_keystore_file(sub)
    Rails.root.join('security', 'sso', "#{sub}_#{Upvs.env}.keystore").to_s
  end

  def sts_keystore_file(sub)
    Rails.root.join('security', 'sts', "#{sub}_#{Upvs.env}.keystore").to_s
  end

  def tls_truststore_file
    Rails.root.join('security', 'tls', "upvs_#{Upvs.env}.truststore").to_s
  end

  def generate_pass(type, sub)
    return 'password' unless Upvs.env.prod?
    salt = ENV.fetch("UPVS_#{type.to_s.upcase}_SALT")
    raise "Short #{type.to_s.upcase} salt" if Upvs.env.prod? && salt.size < 40
    Digest::SHA1.hexdigest("#{salt}:#{sub}")
  end

  def safe_capture(*args)
    output, status = Open3.capture2e(*args.flatten)
    raise SystemCallError, output unless status.success?
    output
  end
end
