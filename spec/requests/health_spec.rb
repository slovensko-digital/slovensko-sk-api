require 'rails_helper'

RSpec.describe 'Health Check' do
  describe 'GET /health' do
    before(:example) { stub_const('ENV', ENV.to_hash.merge('SECRET_KEY_BASE' => SecureRandom.hex)) }

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
