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
      # dev
      'upvs.eks.address' => 'https://edeskii.vyvoj.upvs.globaltel.sk/EKSService.svc',
      'upvs.ez.address' => 'https://vyvoj.upvs.globaltel.sk/ServiceBus/ServiceBusToken.svc',
      'upvs.iam.address' => 'https://authws.vyvoj.upvs.globaltel.sk/iamws17/GetIdentityService',
      'upvs.sktalk.address' => 'https://vyvoj.upvs.globaltel.sk/g2g/G2GServiceBus/ServiceSkTalk3Token.svc',
      'upvs.sts.address' => 'https://authws.vyvoj.upvs.globaltel.sk/sts/wss11x509',

      # fix
      # 'upvs.eks.address' => 'https://eschranka.upvsfixnew.gov.sk/EKSService.svc',
      # 'upvs.ez.address' => 'https://usr.upvsfixnew.gov.sk/ServiceBus/ServiceBusToken.svc',
      # 'upvs.iam.address' => '',
      # 'upvs.sktalk.address' => 'https://uir.upvsfixnew.gov.sk/G2GServiceBus/ServiceSkTalk3Token.svc',
      # 'upvs.sts.address' => 'https://iamwse.upvsfix.gov.sk:8581/sts/wss11x509',

      # 'upvs.log.level' => '',
      # 'upvs.log.console' => 'OFF',
      # 'upvs.log.file' => 'OFF',
      'upvs.log.file.pattern' => 'log/upvs-%d{yyyyMMdd}.log',
      # 'upvs.log.file.history' => '',
      # 'upvs.log.file.size' => '',
      'upvs.log.java.console.level' => 'INFO',

      'upvs.tls.truststore.file' => ENV['UPVS_TLS_TS_FILE'],
      'upvs.tls.truststore.type' => 'JKS',
      'upvs.tls.truststore.password' => ENV['UPVS_TLS_TS_PASS'],

      'upvs.sts.keystore.file' => ENV['UPVS_STS_KS_FILE'],
      'upvs.sts.keystore.type' => 'JKS',
      'upvs.sts.keystore.password' => ENV['UPVS_STS_KS_PASS'],
      'upvs.sts.keystore.alias' => ENV['UPVS_STS_KS_ALIAS'],
      'upvs.sts.keystore.private.password' => ENV['UPVS_STS_KS_PRIVATE_PASS'],

      # 'upvs.sts.saml.assertion' => '<saml:Assertion ID="id-BnEV-0Fk187fjW66RG6B1T3-UXpHhY4sm-zLHwTC" IssueInstant="2018-11-07T20:28:55Z" Version="2.0" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:dsig="http://www.w3.org/2000/09/xmldsig#" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">XXX</saml:Assertion>',
      # 'upvs.sts.saml.assertion' => '',
      #
      # TODO
      # 'upvs.sso.issuer' => 'http://dev.podaas.slovensko.digital',
      # 'upvs.sso.idp.address' => 'https://auth.vyvoj.upvs.globaltel.sk/oamfed/idp/samlv20',
      # 'upvs.sso.idp.callback' => 'http://localhost:3000/auth/saml/callback',

      'upvs.timeout.connection' => '30000',
      'upvs.timeout.receive' => '60000',
    }
  end

  def upvs_proxy(key)
    UpvsProxy.new(upvs_properties(key))
  end
end
