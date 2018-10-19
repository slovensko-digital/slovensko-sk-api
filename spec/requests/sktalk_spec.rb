require 'rails_helper'

RSpec.describe 'SKTalk' do
  describe 'POST /sktalk/receive' do
    it 'receives SKTalk message' do
      post '/sktalk/receive', params: { message: '<xml>' }

      expect(response.status).to eq(200)
      expect(response.body).to eq({ message: '<xml>' }.to_json)
    end

    pending 'receives SKTalk message (with large payload)'

    it 'responds with 400 if request does not contain SKTalk message' do
      post '/sktalk/receive'

      expect(response.status).to eq(400)
      expect(response.body).to eq({ error: 'Missing SKTalk message' }.to_json)
    end

    pending 'responds with 400 if request does not include authentication parameters'
    pending 'responds with 401 if request does not pass authentication'

    pending 'responds with 408 if external service times out'
    pending 'responds with 500 if external service fails'
  end
end
