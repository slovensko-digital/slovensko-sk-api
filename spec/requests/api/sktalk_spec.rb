require 'rails_helper'

RSpec.describe 'SKTalk API' do
  allow_api_token_with_obo_token!
  allow_fixed_sktalk_identifiers!
  skip_upvs_subject_verification!

  let(:token) { api_token_with_subject }
  let(:upvs) { upvs_proxy_double }

  describe 'POST /api/sktalk/receive' do
    let(:params) do
      { message: file_fixture('sktalk/egov_application_general_agenda.xml').read }
    end

    let(:template) do
      file_fixture('sktalk/egov_application_general_agenda.xml').read
    end

    def set_upvs_expectations
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_matching(template)).and_return(0)
    end

    it 'receives message' do
      set_upvs_expectations

      post '/api/sktalk/receive', headers: headers, params: params, as: :json

      expect(response.status).to eq(200)
      expect(response.object).to eq(receive_result: 0)
    end

    it 'does not receive message if URP returns non-zero result' do
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_matching(template)).and_return(3100119)

      post '/api/sktalk/receive', headers: headers, params: params, as: :json

      expect(response.status).to eq(200)
      expect(response.object).to eq(receive_result: 3100119)
    end

    include_examples 'API request media types', post: '/api/sktalk/receive', allow_sub: true, allow_obo_token: true, accept: 'application/json'
    include_examples 'API request authentication', post: '/api/sktalk/receive', allow_sub: true, allow_obo_token: true, require_obo_token_scope: 'sktalk/receive'

    it 'responds with 400 if request does not contain message' do
      post '/api/sktalk/receive', headers: headers, params: params.except(:message), as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No message')
    end

    it 'responds with 400 if request contains invalid message' do
      expect(upvs.sktalk).to be

      post '/api/sktalk/receive', headers: headers, params: params.merge(message: 'INVALID'), as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'Invalid message')
    end

    include_examples 'URP request timeout', post: '/api/sktalk/receive', receive: true

    pending 'responds with 413 if payload is too large'

    it 'responds with 422 if request contains message being saved to drafts' do
      expect(upvs.sktalk).to be

      post '/api/sktalk/receive', headers: headers, params: params.merge(message: file_fixture('sktalk/edesk_save_application_to_drafts_general_agenda.xml').read), as: :json

      expect(response.status).to eq(422)
      expect(response.object).to eq(message: 'Message should not be received as being saved to folder')
    end

    it 'responds with 422 if request contains message being saved to outbox' do
      expect(upvs.sktalk).to be

      post '/api/sktalk/receive', headers: headers, params: params.merge(message: file_fixture('sktalk/edesk_save_application_to_outbox_general_agenda.xml').read), as: :json

      expect(response.status).to eq(422)
      expect(response.object).to eq(message: 'Message should not be received as being saved to folder')
    end

    pending 'responds with 429 if request rate limit exceeds'

    include_examples 'URP request failure', post: '/api/sktalk/receive', receive: true
    include_examples 'UPVS proxy initialization', post: '/api/sktalk/receive', allow_sub: true, allow_obo_token: true, require_obo_token_scope: 'sktalk/receive'
  end

  describe 'POST /api/sktalk/receive_and_save_to_outbox' do
    let(:params) do
      { message: file_fixture('sktalk/egov_application_general_agenda.xml').read }
    end

    let(:template) do
      file_fixture('sktalk/egov_application_general_agenda.xml').read
    end

    def set_upvs_expectations
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_matching(template)).and_return(0)
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_matching(template).saving_to_outbox).and_return(0)
    end

    it 'receives message and saves it to outbox' do
      set_upvs_expectations

      post '/api/sktalk/receive_and_save_to_outbox', headers: headers, params: params, as: :json

      expect(response.status).to eq(200)
      expect(response.object).to eq(receive_result: 0, receive_timeout: false, save_to_outbox_result: 0, save_to_outbox_timeout: false)
    end

    it 'does not receive message or save it to outbox if URP returns non-zero result on receiving' do
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_matching(template)).and_return(3100119)
      expect(upvs.sktalk).not_to receive(:receive)

      post '/api/sktalk/receive_and_save_to_outbox', headers: headers, params: params, as: :json

      expect(response.status).to eq(200)
      expect(response.object).to eq(receive_result: 3100119, receive_timeout: false, save_to_outbox_result: nil, save_to_outbox_timeout: nil)
    end

    it 'receives message but does not save it to outbox if URP returns non-zero result on saving to outbox' do
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_matching(template)).and_return(0)
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_matching(template).saving_to_outbox).and_return(3100119)

      post '/api/sktalk/receive_and_save_to_outbox', headers: headers, params: params, as: :json

      expect(response.status).to eq(200)
      expect(response.object).to eq(receive_result: 0, receive_timeout: false, save_to_outbox_result: 3100119, save_to_outbox_timeout: false)
    end

    include_examples 'API request media types', post: '/api/sktalk/receive_and_save_to_outbox', allow_sub: true, allow_obo_token: true, accept: 'application/json'
    include_examples 'API request authentication', post: '/api/sktalk/receive_and_save_to_outbox', allow_sub: true, allow_obo_token: true, require_obo_token_scope: 'sktalk/receive_and_save_to_outbox'

    it 'responds with 400 if request does not contain message' do
      post '/api/sktalk/receive_and_save_to_outbox', headers: headers, params: params.except(:message), as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No message')
    end

    it 'responds with 400 if request contains invalid message' do
      expect(upvs.sktalk).to be

      post '/api/sktalk/receive_and_save_to_outbox', headers: headers, params: params.merge(message: 'INVALID'), as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'Invalid message')
    end

    include_examples 'URP request timeout', post: '/api/sktalk/receive_and_save_to_outbox', receive: true, save_to_outbox: true

    pending 'responds with 413 if payload is too large'

    it 'responds with 422 if request contains message being saved to drafts' do
      expect(upvs.sktalk).to be

      post '/api/sktalk/receive_and_save_to_outbox', headers: headers, params: params.merge(message: file_fixture('sktalk/edesk_save_application_to_drafts_general_agenda.xml').read), as: :json

      expect(response.status).to eq(422)
      expect(response.object).to eq(message: 'Message should not be received as being saved to folder')
    end

    it 'responds with 422 if request contains message being saved to outbox' do
      expect(upvs.sktalk).to be

      post '/api/sktalk/receive_and_save_to_outbox', headers: headers, params: params.merge(message: file_fixture('sktalk/edesk_save_application_to_outbox_general_agenda.xml').read), as: :json

      expect(response.status).to eq(422)
      expect(response.object).to eq(message: 'Message should not be received as being saved to folder')
    end

    pending 'responds with 429 if request rate limit exceeds'

    include_examples 'URP request failure', post: '/api/sktalk/receive_and_save_to_outbox', receive: true, save_to_outbox: true
    include_examples 'UPVS proxy initialization', post: '/api/sktalk/receive_and_save_to_outbox', allow_sub: true, allow_obo_token: true, require_obo_token_scope: 'sktalk/receive_and_save_to_outbox'
  end

  describe 'POST /api/sktalk/save_to_outbox' do
    let(:params) do
      { message: file_fixture('sktalk/egov_application_general_agenda.xml').read }
    end

    let(:template) do
      file_fixture('sktalk/egov_application_general_agenda.xml').read
    end

    def set_upvs_expectations
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_matching(template).saving_to_outbox).and_return(0)
    end

    it 'saves message to outbox' do
      set_upvs_expectations

      post '/api/sktalk/save_to_outbox', headers: headers, params: params, as: :json

      expect(response.status).to eq(200)
      expect(response.object).to eq(save_to_outbox_result: 0)
    end

    it 'does not save message to outbox if URP returns non-zero result' do
      expect(upvs.sktalk).to receive(:receive).with(sktalk_message_matching(template).saving_to_outbox).and_return(3100119)

      post '/api/sktalk/save_to_outbox', headers: headers, params: params, as: :json

      expect(response.status).to eq(200)
      expect(response.object).to eq(save_to_outbox_result: 3100119)
    end

    include_examples 'API request media types', post: '/api/sktalk/save_to_outbox', allow_sub: true, allow_obo_token: true, accept: 'application/json'
    include_examples 'API request authentication', post: '/api/sktalk/save_to_outbox', allow_sub: true, allow_obo_token: true, require_obo_token_scope: 'sktalk/save_to_outbox'

    it 'responds with 400 if request does not contain message' do
      post '/api/sktalk/save_to_outbox', headers: headers, params: params.except(:message), as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No message')
    end

    it 'responds with 400 if request contains invalid message' do
      expect(upvs.sktalk).to be

      post '/api/sktalk/save_to_outbox', headers: headers, params: params.merge(message: 'INVALID'), as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'Invalid message')
    end

    include_examples 'URP request timeout', post: '/api/sktalk/save_to_outbox', save_to_outbox: true

    pending 'responds with 413 if payload is too large'

    it 'responds with 422 if request contains message being saved to drafts' do
      expect(upvs.sktalk).to be

      post '/api/sktalk/save_to_outbox', headers: headers, params: params.merge(message: file_fixture('sktalk/edesk_save_application_to_drafts_general_agenda.xml').read), as: :json

      expect(response.status).to eq(422)
      expect(response.object).to eq(message: 'Message should not be received as being saved to folder')
    end

    it 'responds with 422 if request contains message being saved to outbox' do
      expect(upvs.sktalk).to be

      post '/api/sktalk/save_to_outbox', headers: headers, params: params.merge(message: file_fixture('sktalk/edesk_save_application_to_outbox_general_agenda.xml').read), as: :json

      expect(response.status).to eq(422)
      expect(response.object).to eq(message: 'Message should not be received as being saved to folder')
    end

    pending 'responds with 429 if request rate limit exceeds'

    include_examples 'URP request failure', post: '/api/sktalk/save_to_outbox', save_to_outbox: true
    include_examples 'UPVS proxy initialization', post: '/api/sktalk/save_to_outbox', allow_sub: true, allow_obo_token: true, require_obo_token_scope: 'sktalk/save_to_outbox'
  end
end
