module ApiRequests
  def setup_api_requests(method_to_path)
    raise ArgumentError if method_to_path.size != 1

    # TODO consider forcing definitions of method + path -> repeating it in examples is prone to typos
    # remove **method_to_path from shared examples below, then add:
    # raise 'No method' unless method_defined?(:method)
    # raise 'No path' unless method_defined?(:path)
    # TODO consider a definition for allow_plain, allow_sub, allow_obo_token -> repeating it in examples is prone to typos
    # raise 'No authenticator options' unless method_defined?(:authenticator_options)
    # TODO then consider using #send_request in each example to eliminate method/path -> repeating it in examples is prone to typos
    # def send_request(*args, **options)
    #   send method, path(args), options.merge(headers: headers, params: params, as: format)
    # end

    let(:headers) { respond_to?(:token) ? Hash['Authorization' => 'Bearer ' + token] : Hash.new } unless method_defined?(:headers)
    let(:params) { Hash.new } unless method_defined?(:params)

    define_method(:set_upvs_expectations) {} unless method_defined?(:set_upvs_expectations)

    # TODO rename to #params_format and reuse #require_request_body? -> this here is pure internal helper
    let(:format) { :json if method_to_path.keys.first != :get && params.any? }

    method_to_path.first
  end

  def allow_api_token_with_obo_token!
    # change current time to SSO response issue instant to be able to generate OBO tokens
    before(:example) { travel_to(sso_response_issued_at) }
  end

  def allow_fixed_sktalk_identifiers!
    # generate fixed SKTalk identifiers to ensure proper validation against file templates
    before(:example) { allow(SktalkMessageBuilder).to receive(:uuid).and_return('00000000-0000-0000-0000-000000000000') }
  end

  def skip_upvs_subject_verification!
    # disable subject verification on UPVS environment level to allow any subject in API tokens
    before(:example) { allow(UpvsEnvironment).to receive(:subject?).and_wrap_original { |_, sub| sub != '?' } }
  end
end

RSpec.configure do |config|
  config.extend ApiRequests

  config.before(:example, type: :request) do
    # invalidate UPVS proxy cache to ensure no instances can be carried over between examples
    UpvsEnvironment.upvs_proxy_cache.invalidate_all
  end
end

shared_examples 'API request media types' do |accept:, require_request_body: nil, expect_response_body: true, **method_to_path|
  method, path = setup_api_requests(method_to_path)

  require_request_body = method.in?([:post, :patch, :put]) if require_request_body.nil?

  # TODO also check Accept-Charset / Content-Type charset -> only utf-8 is allowed

  it 'accepts requests with no Accept' do
    set_upvs_expectations

    send method, path, headers: headers.except('Accept'), params: params, as: format

    expect(response).to be_successful
  end if accept == 'application/json' || accept == 'application/health+json'

  it 'accepts requests with no Content-Type' do
    set_upvs_expectations

    send method, path, headers: headers.except('Content-Type'), params: params, as: format

    expect(response).to be_successful
  end

  it "accepts requests with Accept set to #{accept}" do
    set_upvs_expectations

    send method, path, headers: headers.merge('Accept' => accept), params: params, as: format

    expect(response).to be_successful
  end

  it 'accepts requests with Content-Type set to application/json' do
    set_upvs_expectations

    send method, path, headers: headers.merge('Content-Type' => 'application/json'), params: params, as: format

    expect(response).to be_successful
  end if require_request_body

  it 'responds with 400 if request Content-Type is set' do
    send method, path, headers: headers.merge('Content-Type' => 'application/json'), params: params

    expect(response.status).to eq(400)
    expect(response.object).to eq(message: 'Redundant Content-Type')
  end unless require_request_body

  it 'responds with 400 if request body is not empty' do
    send method, path, headers: headers.merge('RAW_POST_DATA' => '?'), params: params

    expect(response.status).to eq(400)
    expect(response.object).to eq(message: 'Redundant body')
  end unless require_request_body

  it 'responds with 400 if request body is empty' do
    send method, path, headers: headers.merge('RAW_POST_DATA' => ''), params: params, as: :json

    expect(response.status).to eq(400)
    expect(response.object).to eq(message: 'Invalid JSON')
  end if require_request_body

  it 'responds with 400 if request body contains invalid JSON' do
    send method, path, headers: headers.merge('RAW_POST_DATA' => '?'), params: params, as: :json

    expect(response.status).to eq(400)
    expect(response.object).to eq(message: 'Invalid JSON')
  end if require_request_body

  it "responds with 404 if request path ends with #{Mime::Type.lookup(accept).symbol.to_s.upcase} extension" do
    send method, "#{path}.#{Mime::Type.lookup(accept).symbol}", headers: headers, params: params, as: format

    expect(response.status).to eq(404)
    expect(response.body).to be_empty
  end

  it 'responds with 406 if request Accept is not set' do
    send method, path, headers: headers.except('Accept'), params: params, as: format

    expect(response.status).to eq(406)
    expect(response.object).to eq(message: 'Unacceptable Content-Type requested')
  end unless accept == 'application/json' || accept == 'application/health+json'

  it "responds with 406 if request Accept is set but not to #{accept}" do
    send method, path, headers: headers.merge('Accept' => 'text/plain'), params: params, as: format

    expect(response.status).to eq(406)
    expect(response.object).to eq(message: 'Unacceptable Content-Type requested')
  end

  it 'responds with 415 if request Content-Type is set but not to application/json' do
    send method, path, headers: headers.merge('Content-Type' => 'text/plain'), params: params, as: format

    expect(response.status).to eq(415)
    expect(response.object).to eq(message: 'Invalid Content-Type')
  end if require_request_body

  # TODO see https://docs.github.com/en/rest/overview/resources-in-the-rest-api#client-errors
  # it 'responds with 400 if request does not contain message' -> should be 422 with :message + :errors fields
  # it 'responds with 400 if request contains invalid message' -> should be 422 with :message + :errors fields
  # it 'responds with 422 if request body does not match JSON schema', if: require_request_body?(method)

  it "responds as #{accept} in utf-8" do
    set_upvs_expectations

    send method, path, headers: headers, params: params, as: format

    expect(response.content_type).to eq(accept)
    expect(response.charset).to eq('utf-8')
  end if expect_response_body
end

shared_examples 'API request authentication' do |allow_plain: false, allow_sub: false, allow_obo_token: false, **method_to_path|
  raise ArgumentError unless allow_plain || allow_sub || allow_obo_token

  method, path = setup_api_requests(method_to_path)

  it 'accepts authentication via headers' do
    set_upvs_expectations

    send method, path, headers: headers.merge('Authorization' => 'Bearer ' + token), params: params.except(:token), as: format

    expect(response).to be_successful
  end

  it 'accepts authentication via parameters' do
    set_upvs_expectations

    send method, path + "?token=#{token}", headers: headers.except('Authorization'), params: params, as: format

    expect(response).to be_successful
  end

  it 'prefers authentication via headers over parameters' do
    set_upvs_expectations

    send method, path + '?token=INVALID', headers: headers.merge('Authorization' => 'Bearer ' + token), params: params, as: format

    expect(response).to be_successful
  end

  it 'allows authentication via tokens with no identity' do
    set_upvs_expectations

    send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token), params: params, as: format

    expect(response).to be_successful
  end if allow_plain

  it 'allows authentication via tokens with SUB identifier' do
    set_upvs_expectations

    send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token_with_subject), params: params, as: format

    expect(response).to be_successful
  end if allow_sub

  it 'allows authentication via tokens with CTY header + OBO token', if: obo_support? do
    set_upvs_expectations

    send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token_with_obo_token(scopes: [obo_token_scope(method, path)])), params: params, as: format

    expect(response).to be_successful
  end if allow_obo_token

  it 'allows authentication via tokens with CTY header + OBO token', if: sso_support? do
    set_upvs_expectations

    send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token_with_obo_token(scopes: [obo_token_scope(method, path)])), params: params, as: format

    expect(response).to be_successful
  end if allow_obo_token

  it 'responds with 400 if request does not contain any authentication' do
    send method, path, headers: headers.except('Authorization'), params: params.except(token), as: format

    expect(response.status).to eq(400)
    expect(response.object).to eq(message: 'No credentials')
  end

  it 'responds with 401 if authenticating via invalid token' do
    send method, path, headers: headers.merge('Authorization' => 'Bearer ' + 'INVALID'), params: params, as: format

    expect(response.status).to eq(401)
    expect(response.object).to eq(message: 'Bad credentials')
  end

  it 'responds with 401 if authenticating via expired token' do
    # OBO tokens must be generated before any time travels, see authenticity tokens support
    token and travel_to 5.minutes.from_now

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(401)
    expect(response.object).to eq(message: 'Bad credentials')
  end

  it 'responds with 401 if authenticating via replied token' do
    2.times { send method, path, headers: headers, params: params, as: format }

    expect(response.status).to eq(401)
    expect(response.object).to eq(message: 'Bad credentials')
  end

  it 'responds with 401 if authenticating via token with no identity' do
    send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token), params: params, as: format

    expect(response.status).to eq(401)
    expect(response.object).to eq(message: 'Bad credentials')
  end unless allow_plain

  it 'responds with 401 if authenticating via token with SUB identifier' do
    send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token_with_subject), params: params, as: format

    expect(response.status).to eq(401)
    expect(response.object).to eq(message: 'Bad credentials')
  end unless allow_sub

  it 'responds with 401 if authenticating via token with invalid SUB identifier' do
    send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token_with_subject('?')), params: params, as: format

    expect(response.status).to eq(401)
    expect(response.object).to eq(message: 'Bad credentials')
  end if allow_sub

  it 'responds with 401 if authenticating via token with CTY header + OBO token', if: obo_support? do
    send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token_with_obo_token(scopes: [obo_token_scope(method, path)])), params: params, as: format

    expect(response.status).to eq(401)
    expect(response.object).to eq(message: 'Bad credentials')
  end unless allow_obo_token

  it 'responds with 401 if authenticating via token with CTY header + OBO token', if: sso_support? do
    send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token_with_obo_token(scopes: [obo_token_scope(method, path)])), params: params, as: format

    expect(response.status).to eq(401)
    expect(response.object).to eq(message: 'Bad credentials')
  end unless allow_obo_token

  it 'responds with 401 if authenticating via token with CTY header + OBO token with invalid scope', if: obo_support? do
    send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token_with_obo_token(scopes: ['?'])), params: params, as: format

    expect(response.status).to eq(401)
    expect(response.object).to eq(message: 'Bad credentials')
  end if allow_obo_token

  it 'responds with 401 if authenticating via token with CTY header + OBO token with invalid scope', if: sso_support? do
    send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token_with_obo_token(scopes: ['?'])), params: params, as: format

    expect(response.status).to eq(401)
    expect(response.object).to eq(message: 'Bad credentials')
  end if allow_obo_token

  it 'responds with 401 if authenticating via token with CTY header + OBO token', unless: obo_support? do
    # OBO tokens can not be generated nor verified therefore authentication will never succeed
    expect(Environment.obo_token_authenticator).to be_nil
  end
end

shared_examples 'UPVS proxy initialization' do |allow_plain: false, allow_sub: false, allow_obo_token: false, **method_to_path|
  raise ArgumentError unless allow_plain || allow_sub || allow_obo_token

  method, path = setup_api_requests(method_to_path)

  context 'UPVS proxy initialization' do
    let(:upvs) { upvs_proxy_double(expect_upvs_proxy_use: false) }

    it 'does not use any UPVS proxy object when authenticating via token with no identity' do
      expect(UpvsEnvironment).not_to receive(:upvs_proxy)
      expect(UpvsProxy).not_to receive(:new)

      2.times do
        send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token), params: params, as: format

        expect(response).not_to be_successful
      end
    end

    it 'retrieves UPVS proxy object when authenticating via token with SUB identifier' do
      sub = 'CIN-11190868'
      obo = nil

      expect(UpvsEnvironment).to receive(:upvs_proxy).with(sub: sub, obo: obo).and_call_original.at_least(:once)
      expect(UpvsProxy).to receive(:new).with(hash_not_including('upvs.sts.obo')).and_return(upvs).once

      2.times do
        set_upvs_expectations

        send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token_with_subject), params: params, as: format

        expect(response).to be_successful
      end
    end if allow_sub

    it 'does not use any UPVS proxy object when authenticating via token with SUB identifier' do
      expect(UpvsEnvironment).not_to receive(:upvs_proxy)
      expect(UpvsProxy).not_to receive(:new)

      2.times do
        send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token_with_subject), params: params, as: format

        expect(response).not_to be_successful
      end
    end unless allow_sub

    it 'retrieves UPVS proxy object when authenticating via token with CTY header + OBO token', if: sso_support? do
      sub = UpvsEnvironment.sso_proxy_subject
      obo = file_fixture('oam/sso_response_success_assertion.xml').read.strip

      expect(UpvsEnvironment).to receive(:upvs_proxy).with(sub: sub, obo: obo).and_call_original.at_least(:once)
      expect(UpvsProxy).to receive(:new).with(hash_including('upvs.sts.obo' => obo)).and_return(upvs).once

      2.times do
        set_upvs_expectations

        send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token_with_obo_token(scopes: [obo_token_scope(method, path)])), params: params, as: format

        expect(response).to be_successful
      end
    end if allow_obo_token

    it 'does not use any UPVS proxy object when authenticating via token with CTY header + OBO token', if: obo_support? do
      expect(UpvsEnvironment).not_to receive(:upvs_proxy)
      expect(UpvsProxy).not_to receive(:new)

      2.times do
        send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token_with_obo_token(scopes: [obo_token_scope(method, path)])), params: params, as: format

        expect(response).not_to be_successful
      end
    end unless allow_obo_token

    it 'does not use any UPVS proxy object when authenticating via token with CTY header + OBO token', if: sso_support? do
      expect(UpvsEnvironment).not_to receive(:upvs_proxy)
      expect(UpvsProxy).not_to receive(:new)

      2.times do
        send method, path, headers: headers.merge('Authorization' => 'Bearer ' + api_token_with_obo_token(scopes: [obo_token_scope(method, path)])), params: params, as: format

        expect(response).not_to be_successful
      end
    end unless allow_obo_token

    it 'does not use any UPVS proxy object when authenticating via token with CTY header + OBO token', unless: obo_support? do
      # OBO tokens can not be generated nor verified therefore UPVS proxy objects will never be used
      expect(Environment.obo_token_authenticator).to be_nil
    end

    it 'responds with 503 if STS keystore file is incorrect' do
      expect(UpvsProxy).to receive(:new).and_raise(bean_creation_exception_with_cause(java.nio.file.NoSuchFileException, 'INVALID'))

      send method, path, headers: headers, params: params, as: format

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'STS failure')
    end

    it 'responds with 503 if STS keystore pass is incorrect' do
      expect(UpvsProxy).to receive(:new).and_raise(bean_creation_exception_with_cause(java.security.UnrecoverableKeyException, 'Password verification failed'))

      send method, path, headers: headers, params: params, as: format

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'STS failure')
    end

    it 'responds with 503 if STS keystore private key alias is incorrect' do
      # unable to easily instantiate CXF WS policy exception therefore it is simulated by runtime exception here
      expect(UpvsProxy).to receive(:new).and_raise(soap_fault_exception_with_cause(runtime_exception_as_rescuable(org.apache.cxf.ws.policy.PolicyException, 'No certificates for user "INVALID" were found for signature')))

      send method, path, headers: headers, params: params, as: format

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'STS failure')
    end

    it 'responds with 503 if STS keystore private key pass is incorrect' do
      # unable to easily instantiate WSS4J WS security exception therefore it is simulated by runtime exception here
      expect(UpvsProxy).to receive(:new).and_raise(soap_fault_exception_with_cause(runtime_exception_as_rescuable(org.apache.wss4j.common.ext.WSSecurityException, 'The private key for the supplied alias does not exist in the keystore')))

      send method, path, headers: headers, params: params, as: format

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'STS failure')
    end

    it 'responds with 503 if STS keystore certificate is expired' do
      expect(UpvsProxy).to receive(:new).and_raise(soap_certificate_exception)

      send method, path, headers: headers, params: params, as: format

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'STS failure')
    end

    it 'responds with 503 if TLS truststore file is incorrect' do
      expect(UpvsProxy).to receive(:new).and_raise(soap_fault_exception_with_cause(java.io.IOException, 'Could not load keystore resource INVALID'))

      send method, path, headers: headers, params: params, as: format

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'STS failure')
    end

    it 'responds with 503 if TLS truststore pass is incorrect' do
      expect(UpvsProxy).to receive(:new).and_raise(soap_fault_exception_with_cause(java.security.UnrecoverableKeyException, 'Password verification failed'))

      send method, path, headers: headers, params: params, as: format

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'STS failure')
    end

    it 'responds with 503 if TLS truststore certificate is expired' do
      expect(UpvsProxy).to receive(:new).and_raise(soap_certificate_exception)

      send method, path, headers: headers, params: params, as: format

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'STS failure')
    end

    it 'responds with 503 if UPVS connection is refused' do
      expect(UpvsProxy).to receive(:new).and_raise(soap_fault_exception('Connection refused (Connection refused)'))

      send method, path, headers: headers, params: params, as: format

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'ÚPVS connection refused')
    end
  end
end

# TODO rename this to UIR (it is more generic than URP but ok in this case)
shared_examples 'URP request timeout' do |receive: nil, save_to_outbox: nil, **method_to_path|
  raise ArgumentError unless receive || save_to_outbox

  method, path = setup_api_requests(method_to_path)

  it 'responds with 408 if URP raises timeout error' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message).and_raise(soap_timeout_exception)

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(408)
    expect(response.object).to eq(message: 'Operation timeout exceeded')
  end if receive && save_to_outbox == nil

  it 'responds with 408 if URP raises timeout error' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message.saving_to_outbox).and_raise(soap_timeout_exception)

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(408)
    expect(response.object).to eq(message: 'Operation timeout exceeded')
  end if receive == nil && save_to_outbox

  it 'responds with 408 if URP raises timeout error on receiving' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message).and_raise(soap_timeout_exception)
    expect(upvs.sktalk).not_to receive(:receive)

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(408)
    expect(response.object).to eq(receive_result: nil, receive_timeout: true, save_to_outbox_result: nil, save_to_outbox_timeout: nil)
  end if receive && save_to_outbox != nil

  it 'responds with 408 if URP raises timeout error on saving to outbox' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message).and_return(0)
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message.saving_to_outbox).and_raise(soap_timeout_exception)

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(408)
    expect(response.object).to eq(receive_result: 0, receive_timeout: false, save_to_outbox_result: nil, save_to_outbox_timeout: true)
  end if receive && save_to_outbox == true
end

# TODO rename this to UIR (it is more generic than URP but ok in this case)
shared_examples 'URP request failure' do |receive: nil, save_to_outbox: nil, **method_to_path|
  raise ArgumentError unless receive || save_to_outbox

  method, path = setup_api_requests(method_to_path)

  it 'responds with 500 if URP raises internal error' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message).and_raise

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(500)
    expect(response.object).to eq(message: 'Unknown error')
  end if receive && save_to_outbox == nil

  it 'responds with 503 if URP raises SOAP fault' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message).and_raise(soap_fault_exception)

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(503)
    expect(response.object).to eq(message: 'Unknown failure')
  end if receive && save_to_outbox == nil

  it 'responds with 503 if URP raises SOAP fault with UPVS code' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message).and_raise(soap_fault_exception('00000000'))

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(503)
    expect(response.object).to eq(message: 'Unknown failure', fault: { code: '00000000' })
  end if receive && save_to_outbox == nil

  it 'responds with 500 if URP raises internal error' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message.saving_to_outbox).and_raise

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(500)
    expect(response.object).to eq(message: 'Unknown error')
  end if receive == nil && save_to_outbox

  it 'responds with 503 if URP raises SOAP fault' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message.saving_to_outbox).and_raise(soap_fault_exception)

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(503)
    expect(response.object).to eq(message: 'Unknown failure')
  end if receive == nil && save_to_outbox

  it 'responds with 503 if URP raises SOAP fault with UPVS code' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message.saving_to_outbox).and_raise(soap_fault_exception('00000000'))

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(503)
    expect(response.object).to eq(message: 'Unknown failure', fault: { code: '00000000' })
  end if receive == nil && save_to_outbox

  it 'responds with 500 if URP raises internal error on receiving' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message).and_raise
    expect(upvs.sktalk).not_to receive(:receive)

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(500)
    expect(response.object).to eq(message: 'Unknown error')
  end if receive && save_to_outbox != nil

  it 'responds with 500 if URP raises internal error on saving to outbox' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message).and_return(0)
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message.saving_to_outbox).and_raise

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(500)
    expect(response.object).to eq(message: 'Unknown error')
  end if receive && save_to_outbox == true

  it 'responds with 503 if URP raises SOAP fault on receiving' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message).and_raise(soap_fault_exception)
    expect(upvs.sktalk).not_to receive(:receive)

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(503)
    expect(response.object).to eq(message: 'Unknown failure')
  end if receive && save_to_outbox != nil

  it 'responds with 503 if URP raises SOAP fault on saving to outbox' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message).and_return(0)
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message.saving_to_outbox).and_raise(soap_fault_exception)

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(503)
    expect(response.object).to eq(message: 'Unknown failure')
  end if receive && save_to_outbox == true

  it 'responds with 503 if URP raises SOAP fault with UPVS code on receiving' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message).and_raise(soap_fault_exception('00000000'))
    expect(upvs.sktalk).not_to receive(:receive)

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(503)
    expect(response.object).to eq(message: 'Unknown failure', fault: { code: '00000000' })
  end if receive && save_to_outbox != nil

  it 'responds with 503 if URP raises SOAP fault with UPVS code on saving to outbox' do
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message).and_return(0)
    expect(upvs.sktalk).to receive(:receive).with(sktalk_message.saving_to_outbox).and_raise(soap_fault_exception('00000000'))

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(503)
    expect(response.object).to eq(message: 'Unknown failure', fault: { code: '00000000' })
  end if receive && save_to_outbox == true
end

shared_examples 'USR request timeout' do |**method_to_path|
  method, path = setup_api_requests(method_to_path)

  it 'responds with 408 if USR raises timeout error' do
    expect(upvs.ez).to receive(:call_service).and_raise(soap_timeout_exception)

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(408)
    expect(response.object).to eq(message: 'Operation timeout exceeded')
  end
end

shared_examples 'USR request failure' do |**method_to_path|
  method, path = setup_api_requests(method_to_path)

  it 'responds with 500 if USR raises internal error' do
    expect(upvs.ez).to receive(:call_service).and_raise

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(500)
    expect(response.object).to eq(message: 'Unknown error')
  end

  it 'responds with 503 if USR raises SOAP fault' do
    expect(upvs.ez).to receive(:call_service).and_raise(soap_fault_exception)

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(503)
    expect(response.object).to eq(message: 'Unknown failure')
  end

  it 'responds with 503 if USR raises SOAP fault with UPVS code' do
    expect(upvs.ez).to receive(:call_service).and_raise(soap_fault_exception('00000000'))

    send method, path, headers: headers, params: params, as: format

    expect(response.status).to eq(503)
    expect(response.object).to eq(message: 'Unknown failure', fault: { code: '00000000' })
  end
end
