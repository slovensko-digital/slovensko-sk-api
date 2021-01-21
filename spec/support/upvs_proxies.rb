module UpvsProxies
  # TODO use one subject only! (merge STS_CB_SUBJECT / STS_PA_SUBJECT into one variable)
  def corporate_body_subject
    ENV.fetch('STS_CB_SUBJECT').presence || raise('No subject')
  end

  def public_authority_subject
    ENV.fetch('STS_PA_SUBJECT').presence || raise('No subject')
  end

  def allow_upvs_expectations!
    allow(UpvsProxy).to receive(:new).and_wrap_original do |m, *args|
      upvs = m.call(*args)

      # cache Java object proxies of UPVS service objects after actual UPVS proxy object
      # initialization to ensure proper execution of examples which alter UPVS properties

      cache_java_object_proxy!(upvs.eks)
      cache_java_object_proxy!(upvs.ez)
      cache_java_object_proxy!(upvs.iam)
      cache_java_object_proxy!(upvs.sktalk)

      upvs
    end
  end

  def upvs_proxy_double(expect_upvs_proxy_use: true)
    upvs = double(UpvsProxy)

    allow(upvs).to receive(:eks).and_return(double(:eks))
    allow(upvs).to receive(:ez).and_return(double(:ez))
    allow(upvs).to receive(:iam).and_return(double(:iam))
    allow(upvs).to receive(:sktalk).and_return(double(:sktalk))

    # intercept UPVS proxy retrieval via expected call to UPVS environment regardless of initialization arguments,
    # this is useful in shared examples for API requests to abstract from authentication token types

    expect(UpvsEnvironment).to receive(:upvs_proxy).and_return(upvs).at_least(:once) if expect_upvs_proxy_use

    upvs
  end
end

RSpec.configure do |config|
  config.include UpvsProxies
end

shared_examples 'UPVS proxy internals' do |action, exclude_timeout_examples: false|
  context 'UPVS proxy' do
    context 'with incorrect keystore file' do
      let(:properties) { super.merge('upvs.sts.keystore.file' => 'INVALID') }

      it 'raises error' do
        expect { instance_exec(&action) }.to raise_bean_creation_exception_with_cause(java.nio.file.NoSuchFileException, 'INVALID')
      end
    end

    context 'with incorrect keystore pass' do
      let(:properties) { super.merge('upvs.sts.keystore.pass' => 'INVALID') }

      it 'raises error' do
        expect { instance_exec(&action) }.to raise_bean_creation_exception_with_cause(java.security.UnrecoverableKeyException, 'Password verification failed')
      end
    end

    context 'with incorrect keystore private key alias' do
      let(:properties) { super.merge('upvs.sts.keystore.private.alias' => 'INVALID') }

      it 'raises error' do
        expect { instance_exec(&action) }.to raise_soap_fault_exception_with_cause(org.apache.cxf.ws.policy.PolicyException, 'No certificates for user "INVALID" were found for signature')
      end
    end

    context 'with incorrect keystore private key pass' do
      let(:properties) { super.merge('upvs.sts.keystore.private.pass' => 'INVALID') }

      it 'raises error' do
        expect { instance_exec(&action) }.to raise_soap_fault_exception_with_cause(org.apache.wss4j.common.ext.WSSecurityException, 'The private key for the supplied alias does not exist in the keystore')
      end
    end

    context 'with expired keystore certificate' do
      # TODO should raise in case of expired certificate
      # expect { instance_exec(&action) }.to raise_web_service_exception_with_cause(org.apache.cxf.binding.soap.SoapFault, starting_with('00900003'))
      pending 'raises error'
    end

    context 'with incorrect truststore file' do
      let(:properties) { super.merge('upvs.tls.truststore.file' => 'INVALID') }

      it 'raises error' do
        expect { instance_exec(&action) }.to raise_soap_fault_exception_with_cause(java.io.IOException, 'Could not load keystore resource INVALID')
      end
    end

    context 'with incorrect truststore pass' do
      let(:properties) { super.merge('upvs.tls.truststore.pass' => 'INVALID') }

      it 'raises error' do
        expect { instance_exec(&action) }.to raise_soap_fault_exception_with_cause(java.security.UnrecoverableKeyException, 'Password verification failed')
      end
    end

    context 'with expired truststore certificate' do
      # TODO should raise in case of expired certificate
      # expect { instance_exec(&action) }.to raise_web_service_exception_with_cause(org.apache.cxf.binding.soap.SoapFault, starting_with('00900003'))
      pending 'raises error'
    end

    context 'with refused connection' do
      # TODO should raise in case when connecting to IAM but with no permissions (tried on IAM repository search)
      # expect { instance_exec(&action) }.to raise_soap_fault_exception('Connection refused (Connection refused)')
      pending 'raises error'
    end

    context 'with connection timeout', unless: exclude_timeout_examples do
      let(:properties) { super.merge('upvs.timeout.connection' => 2) }

      it 'raises error' do
        expect { instance_exec(&action) }.to raise_soap_fault_exception('Problem writing SAAJ model to stream: connect timed out')
      end
    end

    context 'with receive timeout', unless: exclude_timeout_examples do
      let(:properties) { super.merge('upvs.timeout.receive' => 2) }

      it 'raises error' do
        expect { instance_exec(&action) }.to raise_soap_fault_exception('Problem writing SAAJ model to stream: Read timed out')
      end
    end
  end
end
