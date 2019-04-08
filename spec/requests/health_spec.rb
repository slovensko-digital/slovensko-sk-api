require 'rails_helper'

RSpec.describe 'Health Check' do
  before(:example) do
    stub_const('ENV', ENV.to_hash.merge('SECRET_KEY_BASE' => SecureRandom.hex))
  end

  before(:example) do
    allow(KeyStore).to receive(:new).with(any_args).and_return(keystore = double)
    allow(keystore).to receive_message_chain(:certificate, :not_after, :to_s).and_return(1.year.from_now.to_s)
  end

  before(:example) do
    allow(UpvsEnvironment).to receive_message_chain(:eform_service, :fetch_xsd_schema)
    allow(UpvsEnvironment).to receive_message_chain(:upvs_proxy, :sktalk)
  end

  context 'with UPVS SSO support', sso: true do
    describe 'GET /health' do
      it 'checks health' do
        get '/health'

        expect(response.status).to eq(200)
        expect(response.body).to eq({ status: 'pass' }.to_json)

        expect(response.content_type).to eq('application/json')
        expect(response.charset).to eq('utf-8')
      end

      pending
    end

    describe 'GET /health?check=heartbeats' do
      pending
    end

    describe 'GET /health?check=upvs' do
      pending
    end
  end

  context 'without UPVS SSO support', sso: false do
    describe 'GET /health' do
      it 'checks health' do
        get '/health'

        expect(response.status).to eq(200)
        expect(response.body).to eq({ status: 'pass' }.to_json)

        expect(response.content_type).to eq('application/json')
        expect(response.charset).to eq('utf-8')
      end

      pending
    end

    describe 'GET /health?check=heartbeats' do
      pending
    end

    describe 'GET /health?check=upvs' do
      pending
    end
  end
end
