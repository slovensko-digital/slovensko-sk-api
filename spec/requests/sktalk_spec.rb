require 'rails_helper'

RSpec.describe 'SKTalk' do
  let(:sktalk_service) { double }

  before(:example) do
    allow(UpvsEnvironment).to receive(:sktalk_service).with('KEY').and_return(sktalk_service)
  end

  describe 'POST /sktalk/receive' do
    it 'receives message' do
      expect(sktalk_service).to receive(:receive).with('<xml>').and_return(0)

      post '/sktalk/receive', params: { key: 'KEY', message: '<xml>' }

      expect(response.status).to eq(200)
      expect(response.body).to eq({ result: 0 }.to_json)
    end

    pending 'receives message (largest possible payload)'

    it 'responds with 400 if request does not contain authentication parameters' do
      post '/sktalk/receive', params: {}

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No credentials' }.to_json)
    end

    it 'responds with 400 if request does not contain message to receive' do
      post '/sktalk/receive', params: { key: 'KEY' }

      expect(response.status).to eq(400)
      expect(response.body).to eq({ message: 'No message' }.to_json)
    end

    pending 'responds with 401 if authentication does not pass'

    pending 'responds with 408 if external service times out'

    pending 'responds with 413 if payload is too large'

    pending 'responds with 429 if request rate limit exceeds'

    pending 'responds with 500 if external service fails'

    pending 'responds with 500 if anything else fails'
  end
end
