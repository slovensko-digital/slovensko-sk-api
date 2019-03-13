require 'rails_helper'

RSpec.describe 'SKTalk API' do
  let!(:token) { api_token_with_obo_token_from_response(file_fixture('oam/sso_response_success.xml').read, scopes: ['sktalk/receive', 'sktalk/receive_and_save_to_outbox']) }
  let!(:message) { file_fixture('sktalk/egov_application_general_agenda.xml').read }

  before(:example) do
    allow(UpvsProxy).to receive(:new).and_wrap_original { double }
  end

  before(:example) { travel_to '2018-11-28T20:26:16Z' }

  after(:example) { travel_back }

  describe 'POST /api/sktalk/receive' do
    before(:example) do
      allow_any_instance_of(SktalkReceiver).to receive(:receive).with(message).and_return(0)
    end

    it 'receives message' do
      post '/api/sktalk/receive', headers: { 'Authorization' => 'Bearer ' + token }, params: { message: message }

      expect(response.status).to eq(200)
      expect(response.body).to eq({ receive_result: 0 }.to_json)

      expect(response.content_type).to eq('application/json')
      expect(response.charset).to eq('utf-8')
    end

    pending 'receives message in request with largest possible payload'

    it 'supports authentication via headers' do
      post '/api/sktalk/receive', headers: { 'Authorization' => 'Bearer ' + token }, params: { message: message }

      expect(response.status).to eq(200)
    end

    it 'supports authentication via parameters' do
      post '/api/sktalk/receive', params: { token: token, message: message }

      expect(response.status).to eq(200)
    end

    it 'prefers authentication via headers over parameters' do
      post '/api/sktalk/receive', headers: { 'Authorization' => 'Bearer ' + token }, params: { token: 'INVALID', message: message }

      expect(response.status).to eq(200)
    end

    it 'allows authentication via tokens with TA key' do
      post '/api/sktalk/receive', headers: { 'Authorization' => 'Bearer ' + api_token_with_ta_key }, params: { message: message }

      expect(response.status).to eq(200)
    end

    it 'allows authentication via tokens with OBO token' do
      post '/api/sktalk/receive', headers: { 'Authorization' => 'Bearer ' + api_token_with_obo_token_from_response(file_fixture('oam/sso_response_success.xml').read, scopes: ['sktalk/receive']) }, params: { message: message }

      expect(response.status).to eq(200)
    end

    it 'responds with 400 if request does not contain any authentication' do
      post '/api/sktalk/receive', params: { message: message }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No credentials' }.to_json)
    end

    it 'responds with 400 if request does not contain message to receive' do
      post '/api/sktalk/receive', headers: { 'Authorization' => 'Bearer ' + token }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No message' }.to_json)
    end

    it 'responds with 400 if request contains malformed message to receive' do
      expect_any_instance_of(SktalkReceiver).to receive(:receive).with('INVALID').and_call_original

      post '/api/sktalk/receive', headers: { 'Authorization' => 'Bearer ' + token }, params: { message: 'INVALID' }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'Malformed message' }.to_json)
    end

    it 'responds with 401 if authenticating via expired token' do
      travel_to Time.now + 20.minutes

      post '/api/sktalk/receive', headers: { 'Authorization' => 'Bearer ' + token }, params: { message: message }

      expect(response.status).to eq(401)
      expect(response.body).to eq({ message: 'Bad credentials' }.to_json)
    end

    it 'responds with 408 if external service times out' do
      expect_any_instance_of(SktalkReceiver).to receive(:receive).with(message).and_raise(execution_exception(soap_fault_exception('connect timed out')))

      post '/api/sktalk/receive', headers: { 'Authorization' => 'Bearer ' + token }, params: { message: message }

      expect(response.status).to eq(408)
      expect(response.body).to eq({ message: 'Operation timeout exceeded' }.to_json)
    end

    pending 'responds with 413 if payload is too large'

    pending 'responds with 429 if request rate limit exceeds'

    pending 'responds with 500 if external service fails'

    pending 'responds with 500 if anything else fails'

    context 'UPVS' do
      let(:assertion) { file_fixture('oam/sso_response_success_assertion.xml').read.strip }

      before(:example) { UpvsEnvironment.upvs_proxy_cache.invalidate_all }

      it 'retrieves TA proxy object when authenticating via token with TA key' do
        expect(UpvsEnvironment).to receive(:upvs_proxy).with(assertion: nil).and_call_original.at_least(:once)
        expect(UpvsProxy).to receive(:new).with(hash_not_including('upvs.sts.saml.assertion')).and_return(double).once

        2.times do
          post '/api/sktalk/receive', headers: { 'Authorization' => 'Bearer ' + api_token_with_ta_key }, params: { message: message }

          expect(response.status).to eq(200)
        end
      end

      it 'retrieves OBO proxy object when authenticating via token with OBO token' do
        expect(UpvsEnvironment).to receive(:upvs_proxy).with(assertion: assertion).and_call_original.at_least(:once)
        expect(UpvsProxy).to receive(:new).with(hash_including('upvs.sts.saml.assertion' => assertion)).and_return(double).once

        2.times do
          post '/api/sktalk/receive', headers: { 'Authorization' => 'Bearer ' + api_token_with_obo_token_from_response(file_fixture('oam/sso_response_success.xml').read, scopes: ['sktalk/receive']) }, params: { message: message }

          expect(response.status).to eq(200)
        end
      end
    end
  end

  describe 'POST /api/sktalk/receive_and_save_to_outbox' do
    before(:example) do
      allow_any_instance_of(SktalkReceiver).to receive(:receive).with(message).and_return(0)
      allow_any_instance_of(SktalkReceiver).to receive(:save_to_outbox).with(message).and_return(0)
    end

    it 'receives message and saves it to outbox' do
      post '/api/sktalk/receive_and_save_to_outbox', headers: { 'Authorization' => 'Bearer ' + token }, params: { message: message }

      expect(response.status).to eq(200)
      expect(response.body).to eq({ receive_result: 0, save_to_outbox_result: 0 }.to_json)

      expect(response.content_type).to eq('application/json')
      expect(response.charset).to eq('utf-8')
    end

    pending 'receives message and saves it to outbox in request with largest possible payload'

    it 'supports authentication via headers' do
      post '/api/sktalk/receive_and_save_to_outbox', headers: { 'Authorization' => 'Bearer ' + token }, params: { message: message }

      expect(response.status).to eq(200)
    end

    it 'supports authentication via parameters' do
      post '/api/sktalk/receive_and_save_to_outbox', params: { token: token, message: message }

      expect(response.status).to eq(200)
    end

    it 'prefers authentication via headers over parameters' do
      post '/api/sktalk/receive_and_save_to_outbox', headers: { 'Authorization' => 'Bearer ' + token }, params: { token: 'INVALID', message: message }

      expect(response.status).to eq(200)
    end

    it 'allows authentication via tokens with TA key' do
      post '/api/sktalk/receive_and_save_to_outbox', headers: { 'Authorization' => 'Bearer ' + api_token_with_ta_key }, params: { message: message }

      expect(response.status).to eq(200)
    end

    it 'allows authentication via tokens with OBO token' do
      post '/api/sktalk/receive_and_save_to_outbox', headers: { 'Authorization' => 'Bearer ' + api_token_with_obo_token_from_response(file_fixture('oam/sso_response_success.xml').read, scopes: ['sktalk/receive_and_save_to_outbox']) }, params: { message: message }

      expect(response.status).to eq(200)
    end

    it 'responds with 400 if request does not contain any authentication' do
      post '/api/sktalk/receive_and_save_to_outbox', params: { message: message }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No credentials' }.to_json)
    end

    it 'responds with 400 if request does not contain message to receive' do
      post '/api/sktalk/receive_and_save_to_outbox', headers: { 'Authorization' => 'Bearer ' + token }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No message' }.to_json)
    end

    it 'responds with 400 if request contains malformed message to receive' do
      expect_any_instance_of(SktalkReceiver).to receive(:receive).with('INVALID').and_call_original

      post '/api/sktalk/receive_and_save_to_outbox', headers: { 'Authorization' => 'Bearer ' + token }, params: { message: 'INVALID' }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'Malformed message' }.to_json)
    end

    it 'responds with 401 if authenticating via expired token' do
      travel_to Time.now + 20.minutes

      post '/api/sktalk/receive_and_save_to_outbox', headers: { 'Authorization' => 'Bearer ' + token }, params: { message: message }

      expect(response.status).to eq(401)
      expect(response.body).to eq({ message: 'Bad credentials' }.to_json)
    end

    it 'responds with 408 if external service times out' do
      expect_any_instance_of(SktalkReceiver).to receive(:receive).with(message).and_raise(execution_exception(soap_fault_exception('connect timed out')))

      post '/api/sktalk/receive_and_save_to_outbox', headers: { 'Authorization' => 'Bearer ' + token }, params: { message: message }

      expect(response.status).to eq(408)
      expect(response.body).to eq({ message: 'Operation timeout exceeded' }.to_json)
    end

    pending 'responds with 413 if payload is too large'

    pending 'responds with 429 if request rate limit exceeds'

    pending 'responds with 500 if external service fails'

    pending 'responds with 500 if anything else fails'

    context 'UPVS' do
      let(:assertion) { file_fixture('oam/sso_response_success_assertion.xml').read.strip }

      before(:example) { UpvsEnvironment.upvs_proxy_cache.invalidate_all }

      it 'retrieves TA proxy object when authenticating via token with TA key' do
        expect(UpvsEnvironment).to receive(:upvs_proxy).with(assertion: nil).and_call_original.at_least(:once)
        expect(UpvsProxy).to receive(:new).with(hash_not_including('upvs.sts.saml.assertion')).and_return(double).once

        2.times do
          post '/api/sktalk/receive_and_save_to_outbox', headers: { 'Authorization' => 'Bearer ' + api_token_with_ta_key }, params: { message: message }

          expect(response.status).to eq(200)
        end
      end

      it 'retrieves OBO proxy object when authenticating via token with OBO token' do
        expect(UpvsEnvironment).to receive(:upvs_proxy).with(assertion: assertion).and_call_original.at_least(:once)
        expect(UpvsProxy).to receive(:new).with(hash_including('upvs.sts.saml.assertion' => assertion)).and_return(double).once

        2.times do
          post '/api/sktalk/receive_and_save_to_outbox', headers: { 'Authorization' => 'Bearer ' + api_token_with_obo_token_from_response(file_fixture('oam/sso_response_success.xml').read, scopes: ['sktalk/receive_and_save_to_outbox']) }, params: { message: message }

          expect(response.status).to eq(200)
        end
      end
    end
  end
end
