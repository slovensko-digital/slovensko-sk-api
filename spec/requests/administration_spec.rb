require 'rails_helper'

RSpec.describe 'Administration' do
  allow_api_token_with_obo_token!

  let(:token) { api_token }

  describe 'POST /administration/certificates' do
    let(:params) do
      {
        id: 'iscep_00956852_10236',
        cin: '00956852_10236',
      }
    end

    after(:example) { suppress(SystemCallError) { UpvsEnvironment.delete_subject('iscep_00956852_10236') }}

    it 'creates certificate' do
      post '/administration/certificates', headers: headers, params: params, as: :json

      expect(response.status).to eq(201)
      expect(response.body).to be_empty

      expect(UpvsEnvironment.subject?('iscep_00956852_10236')).to eq(true)
    end

    context 'keystore' do
      subject { Rails.root.join('security', 'sts', "iscep_00956852_10236_#{Upvs.env}.keystore") }

      before(:example) { allow(Upvs).to receive(:env).and_return(ActiveSupport::StringInquirer.new('prod')) }
      before(:example) { stub_const('ENV', ENV.merge('UPVS_KS_SALT' => SecureRandom.hex(20), 'UPVS_PK_SALT' => SecureRandom.hex(20))) }

      it 'has JKS format' do
        post '/administration/certificates', headers: headers, params: params, as: :json

        expect(subject.read(4).unpack('H*').first).to eq('feedfeed')
      end

      it 'has two passwords' do
        ks, pk = ENV.values_at('UPVS_KS_SALT', 'UPVS_PK_SALT').map { |salt| Digest::SHA1.hexdigest("#{salt}:#{params[:id]}") }

        post '/administration/certificates', headers: headers, params: params, as: :json

        expect(ks).not_to eq(pk)
        expect(KeyStore.new(subject.to_s, ks).private_key(params[:id], pk)).to be
      end
    end

    pending 'responds with 400 if request does not contain identifier'
    pending 'responds with 400 if request contains malicious identifier' # TODO check against shell escape stuff

    pending 'responds with 400 if request does not contain CIN'
    pending 'responds with 400 if request contains malicious CIN' # TODO check against shell escape stuff

    it 'responds with 409 if certificate already exists' do
      UpvsEnvironment.create_subject('iscep_00956852_10236', cin: '00956852_10236')

      post '/administration/certificates', headers: headers, params: params, as: :json

      expect(response.status).to eq(409)
      expect(response.body).to be_empty
    end

    include_examples 'API request media types', post: '/administration/certificates', accept: 'application/json', expect_response_body: false
    include_examples 'API request authentication', post: '/administration/certificates', allow_plain: true
  end

  describe 'GET /administration/certificates/{id}' do
    before(:example) { UpvsEnvironment.create_subject('iscep_00956852_10236', cin: '00956852_10236') }

    after(:example) { suppress(SystemCallError) { UpvsEnvironment.delete_subject('iscep_00956852_10236') }}

    it 'gets certificate' do
      get '/administration/certificates/iscep_00956852_10236', headers: headers

      expect(response.status).to eq(200)
      expect(response.object.keys).to contain_exactly(:certificate, :fingerprint, :not_after, :subject)

      expect(response.object[:certificate]).to match(/\A-{5}BEGIN CERTIFICATE-{5}\n.+\n-{5}END CERTIFICATE-{5}\n\z/m)
      expect(response.object[:fingerprint]).to match(/\A[0-9a-f]{64}\z/)
      expect(response.object[:not_after]).to eq(response.object[:not_after].in_time_zone.as_json)
      expect(response.object[:subject]).to eq("ico-00956852_10236")
    end

    pending 'responds with 400 if request contains malicious identifier' # TODO check against shell escape stuff

    it 'responds with 404 if certificate does not exist' do
      UpvsEnvironment.delete_subject('iscep_00956852_10236')

      get '/administration/certificates/iscep_00956852_10236', headers: headers

      expect(response.status).to eq(404)
      expect(response.body).to be_empty
    end

    include_examples 'API request media types', get: '/administration/certificates/iscep_00956852_10236', accept: 'application/json'
    include_examples 'API request authentication', get: '/administration/certificates/iscep_00956852_10236', allow_plain: true
  end

  describe 'DELETE /administration/certificates/{id}' do
    before(:example) { UpvsEnvironment.create_subject('iscep_00956852_10236', cin: '00956852_10236') }

    after(:example) { suppress(SystemCallError) { UpvsEnvironment.delete_subject('iscep_00956852_10236') }}

    it 'deletes certificate' do
      delete '/administration/certificates/iscep_00956852_10236', headers: headers

      expect(response.status).to eq(204)
      expect(response.body).to be_empty

      expect(UpvsEnvironment.subject?('iscep_00956852_10236')).to eq(false)
    end

    pending 'responds with 400 if request contains malicious identifier' # TODO check against shell escape stuff

    it 'responds with 404 if certificate does not exist' do
      UpvsEnvironment.delete_subject('iscep_00956852_10236')

      delete '/administration/certificates/iscep_00956852_10236', headers: headers

      expect(response.status).to eq(404)
      expect(response.body).to be_empty
    end

    include_examples 'API request media types', delete: '/administration/certificates/iscep_00956852_10236', accept: 'application/json', expect_response_body: false
    include_examples 'API request authentication', delete: '/administration/certificates/iscep_00956852_10236', allow_plain: true
  end

  describe 'GET /administration/eform/synchronize' do
    it 'schedules synchronization' do
      expect(DownloadFormTemplatesJob).to receive(:perform_later)

      get '/administration/eform/synchronize', headers: headers

      expect(response.status).to eq(204)
      expect(response.body).to be_empty
    end

    include_examples 'API request media types', get: '/administration/eform/synchronize', accept: 'application/json', expect_response_body: false
    include_examples 'API request authentication', get: '/administration/eform/synchronize', allow_plain: true
  end
end
