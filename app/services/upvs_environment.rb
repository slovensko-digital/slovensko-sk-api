module UpvsEnvironment
  extend self

  def sktalk_receiver(key)
    SktalkReceiver.new(upvs_proxy(key))
  end

  def sktalk_saver(key)
    SktalkSaver.new(sktalk_receiver(key))
  end

  def upvs_properties(key)
    # TODO

    {
      # 'upvs.eks.address' => 'https://edeskii.vyvoj.upvs.globaltel.sk/EKSService.svc',
      # 'upvs.ez.address' => 'https://vyvoj.upvs.globaltel.sk/ServiceBus/ServiceBusToken.svc',
      # 'upvs.iam.address' => 'https://authws.vyvoj.upvs.globaltel.sk/iamws17/GetIdentityService',
      # 'upvs.sktalk.address' => 'https://vyvoj.upvs.globaltel.sk/g2g/G2GServiceBus/ServiceSkTalk3Token.svc',
      # 'upvs.sts.address' => 'https://authws.vyvoj.upvs.globaltel.sk/sts/wss11x509',

      'upvs.eks.address' => 'https://eschranka.upvsfixnew.gov.sk/EKSService.svc',
      'upvs.ez.address' => 'https://usr.upvsfixnew.gov.sk/ServiceBus/ServiceBusToken.svc',
      'upvs.iam.address' => '',
      'upvs.sktalk.address' => 'https://uir.upvsfixnew.gov.sk/G2GServiceBus/ServiceSkTalk3Token.svc',
      'upvs.sts.address' => 'https://iamwse.upvsfix.gov.sk:8581/sts/wss11x509',

      'upvs.log.console' => 'OFF',
      'upvs.log.file.pattern' => 'log/upvs-%d{yyyyMMdd}.log',
      'upvs.log.java.console.level' => 'INFO',

      'upvs.ssl.truststore.file' => 'tmp/security/upvs-fix.truststore',
      'upvs.ssl.truststore.type' => 'JKS',
      'upvs.ssl.truststore.password' => ENV['UPVS_TS_PASS'],

      'upvs.crypto.keystore.file' => 'tmp/security/irvin-fix.keystore',
      'upvs.crypto.keystore.alias' => 'irvin_upvsfix',
      'upvs.crypto.keystore.type' => 'JKS',
      'upvs.crypto.keystore.password' => ENV['UPVS_KS_PASS'],
      'upvs.crypto.keystore.key' => ENV['UPVS_KS_KEY'],
    }
  end

  def upvs_proxy(key)
    UpvsProxy.new(upvs_properties(key))
  end
end
