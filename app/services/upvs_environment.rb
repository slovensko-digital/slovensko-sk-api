module UpvsEnvironment
  extend self

  def sktalk_receiver(key)
    SktalkReceiver.new(upvs_proxy(key))
  end

  def upvs_properties(key)
    # TODO

    {
      'upvs.eks.address' => 'https://edeskii.vyvoj.upvs.globaltel.sk/EKSService.svc',
      'upvs.ez.address' => 'https://vyvoj.upvs.globaltel.sk/ServiceBus/ServiceBusToken.svc',
      'upvs.iam.address' => 'https://authws.vyvoj.upvs.globaltel.sk/iamws17/GetIdentityService',
      'upvs.sktalk.address' => 'https://vyvoj.upvs.globaltel.sk/g2g/G2GServiceBus/ServiceSkTalk3Token.svc',
      'upvs.sts.address' => 'https://authws.vyvoj.upvs.globaltel.sk/sts/wss11x509',

      'upvs.log.file.pattern' => 'log/upvsdev-%d{yyyyMMdd}.log',
      'upvs.log.java.console.level' => 'INFO',

      'upvs.ssl.truststore.file' => 'tmp/upvsdev.truststore',
      'upvs.ssl.truststore.type' => 'JKS',
      'upvs.ssl.truststore.password' => ENV['UPVS_TS_PASS'],

      'upvs.crypto.keystore.file' => 'tmp/irvin_upvsdev.keystore',
      'upvs.crypto.keystore.alias' => 'irvin_upvsdev',
      'upvs.crypto.keystore.type' => 'JKS',
      'upvs.crypto.keystore.password' => ENV['UPVS_KS_PASS'],
      'upvs.crypto.keystore.key' => ENV['UPVS_KS_KEY'],
    }
  end

  def upvs_proxy(key)
    UpvsProxy.new(upvs_properties(key))
  end
end
