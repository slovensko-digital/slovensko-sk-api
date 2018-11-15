module UpvsEnvironment
  extend self

  def assertion_store
    # TODO there is also a ActiveSupport::Cache::Store::RedisStore
    @assertion_store ||= ActiveSupport::Cache::MemoryStore.new
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

  def upvs_proxy(assertion)
    UpvsProxy.new(upvs_properties(assertion))
  end
end
