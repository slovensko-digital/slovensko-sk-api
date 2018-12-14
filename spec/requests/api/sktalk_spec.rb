require 'rails_helper'

RSpec.describe 'SKTalk API' do
  let(:sktalk_receiver) { instance_double(SktalkReceiver) }

  let!(:token) do
    response = OneLogin::RubySaml::Response.new(file_fixture('oam/response_success.xml').read)
    scopes = ['sktalk/receive', 'sktalk/receive_and_save_to_outbox']

    obo_token = travel_to(response.not_before) do
      Environment.obo_token_authenticator.generate_token(response, scopes: scopes)
    end

    header = { cty: 'JWT' }
    payload = { exp: response.not_on_or_after.to_i, jti: SecureRandom.uuid, obo: obo_token }

    JWT.encode(payload, api_token_key_pair, 'RS256', header)
  end

  let!(:message) { file_fixture('sktalk/egov_application_general_agenda.xml').read }

  before(:example) do
    assertion = file_fixture('oam/response_success_assertion.xml').read.strip

    allow(UpvsEnvironment).to receive(:sktalk_receiver).with(assertion).and_return(sktalk_receiver)
  end

  before(:example) { travel_to '2018-11-28T20:26:16Z' }

  after(:example) { travel_back }

  describe 'POST /api/sktalk/receive' do
    it 'receives message' do
      expect(sktalk_receiver).to receive(:receive).with(message).and_return(0)

      post '/api/sktalk/receive', params: { token: token, message: message }

      expect(response.status).to eq(200)
      expect(response.body).to eq({ receive_result: 0 }.to_json)
    end

    pending 'receives message in request with largest possible payload'

    it 'responds with 400 if request does not contain authentication parameters' do
      post '/api/sktalk/receive', params: { message: message }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No credentials' }.to_json)
    end

    it 'responds with 400 if request does not contain message to receive' do
      post '/api/sktalk/receive', params: { token: token }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No message' }.to_json)
    end

    it 'responds with 401 if authentication does not pass' do
      travel_to Time.now + 20.minutes

      post '/api/sktalk/receive', params: { token: token, message: message }

      expect(response.status).to eq(401)
      expect(response.body).to eq({ message: 'Bad credentials' }.to_json)
    end

    pending 'responds with 408 if external service times out'

    pending 'responds with 413 if payload is too large'

    pending 'responds with 429 if request rate limit exceeds'

    pending 'responds with 500 if external service fails'

    pending 'responds with 500 if anything else fails'
  end

  describe 'POST /api/sktalk/receive_and_save_to_outbox' do
    it 'receives message and saves it to outbox' do
      expect(sktalk_receiver).to receive(:receive).with(message).and_return(0)
      expect(sktalk_receiver).to receive(:save_to_outbox).with(message).and_return(0)

      post '/api/sktalk/receive_and_save_to_outbox', params: { token: token, message: message }

      expect(response.status).to eq(200)
      expect(response.body).to eq({ receive_result: 0, save_to_outbox_result: 0 }.to_json)
    end

    pending 'receives message and saves it to outbox in request with largest possible payload'

    it 'responds with 400 if request does not contain authentication parameters' do
      post '/api/sktalk/receive_and_save_to_outbox', params: { message: message }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No credentials' }.to_json)
    end

    it 'responds with 400 if request does not contain message to receive' do
      post '/api/sktalk/receive_and_save_to_outbox', params: { token: token }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No message' }.to_json)
    end

    it 'responds with 401 if authentication does not pass' do
      travel_to Time.now + 20.minutes

      post '/api/sktalk/receive_and_save_to_outbox', params: { token: token, message: message }

      expect(response.status).to eq(401)
      expect(response.body).to eq({ message: 'Bad credentials' }.to_json)
    end

    pending 'responds with 408 if external service times out'

    pending 'responds with 413 if payload is too large'

    pending 'responds with 429 if request rate limit exceeds'

    pending 'responds with 500 if external service fails'

    pending 'responds with 500 if anything else fails'
  end
end
