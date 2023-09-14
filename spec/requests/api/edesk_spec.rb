require 'rails_helper'

RSpec.describe 'eDesk API' do
  allow_api_token_with_obo_token!
  allow_fixed_sktalk_identifiers!
  skip_upvs_subject_verification!

  let(:token) { api_token_with_subject }
  let(:upvs) { upvs_proxy_double }

  describe 'GET /api/edesk/folders' do
    def set_upvs_expectations
      expect(upvs.eks).to receive(:get_folders).and_return(ekr_response('eks/get_folders_response.xml').get_folders_result.value)
    end

    it 'gets folders' do
      set_upvs_expectations

      get '/api/edesk/folders', headers: headers

      expect(response.status).to eq(200)
      expect(response.object).to eq(JSON.parse(file_fixture('api/edesk/folders.json').read, symbolize_names: true))
    end

    include_examples 'API request media types', get: '/api/edesk/folders', accept: 'application/json'
    include_examples 'API request authentication', get: '/api/edesk/folders', allow_sub: true

    pending 'responds with 404 if box is inaccessible (hides that it may exist)'

    it 'responds with 404 if box does not exist' do
      expect(upvs.eks).to receive(:get_folders).and_raise(eks_get_folders_fault('eks/get_folders/box_not_exist_fault.xml'))

      get '/api/edesk/folders', headers: headers

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Box not found')
    end

    it 'responds with 408 if EKR raises timeout error' do
      expect(upvs.eks).to receive(:get_folders).and_raise(soap_timeout_exception)

      get '/api/edesk/folders', headers: headers

      expect(response.status).to eq(408)
      expect(response.object).to eq(message: 'Operation timeout exceeded')
    end

    it 'responds with 409 if box is not active' do
      expect(upvs.eks).to receive(:get_folders).and_raise(eks_get_folders_fault('eks/get_folders/box_inactive_fault.xml'))

      get '/api/edesk/folders', headers: headers

      expect(response.status).to eq(409)
      expect(response.object).to eq(message: 'Box inactive')
    end

    pending 'responds with 429 if request rate limit exceeds'

    it 'responds with 500 if EKR raises internal error' do
      expect(upvs.eks).to receive(:get_folders).and_raise

      get '/api/edesk/folders', headers: headers

      expect(response.status).to eq(500)
      expect(response.object).to eq(message: 'Unknown error')
    end

    it 'responds with 503 if EKR raises eDesk fault' do
      expect(upvs.eks).to receive(:get_folders).and_raise(eks_get_folders_fault('eks/general_fault.xml'))

      get '/api/edesk/folders', headers: headers

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'EKR failure')
    end

    it 'responds with 503 if EKR raises SOAP fault' do
      expect(upvs.eks).to receive(:get_folders).and_raise(soap_fault_exception)

      get '/api/edesk/folders', headers: headers

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'Unknown failure')
    end

    include_examples 'UPVS proxy initialization', get: '/api/edesk/folders', allow_sub: true
  end

  describe 'GET /api/edesk/folders/{id}/messages' do
    def set_upvs_expectations
      expect(upvs.eks).to receive(:get_messages).with(20378640, any_args).and_return(ekr_response('eks/get_messages_response.xml').get_messages_result.value)
    end

    it 'gets messages' do
      set_upvs_expectations

      get '/api/edesk/folders/20378640/messages', headers: headers

      expect(response.status).to eq(200)
      expect(response.object).to eq(JSON.parse(file_fixture('api/edesk/messages.json').read, symbolize_names: true))
    end

    context 'pagination' do
      it 'returns messages in folder at given page' do
        expect(upvs.eks).to receive(:get_messages).with(20378640, 50, 200).and_return(ekr_response('eks/get_messages_response.xml').get_messages_result.value)

        get '/api/edesk/folders/20378640/messages', headers: headers, params: { page: 5 }

        expect(response.status).to eq(200)
      end

      it 'returns messages in folder at given page and with given per page' do
        expect(upvs.eks).to receive(:get_messages).with(20378640, 25, 100).and_return(ekr_response('eks/get_messages_response.xml').get_messages_result.value)

        get '/api/edesk/folders/20378640/messages', headers: headers, params: { page: 5, per_page: 25 }

        expect(response.status).to eq(200)
      end

      it 'returns messages in folder with given per page' do
        expect(upvs.eks).to receive(:get_messages).with(20378640, 25, 0).and_return(ekr_response('eks/get_messages_response.xml').get_messages_result.value)

        get '/api/edesk/folders/20378640/messages', headers: headers, params: { per_page: 25 }

        expect(response.status).to eq(200)
      end

      it 'responds with 400 if given page number is invalid' do
        get '/api/edesk/folders/20378640/messages', headers: headers, params: { page: '1x' }

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Invalid page number')
      end

      it 'responds with 400 if given page number is zero' do
        get '/api/edesk/folders/20378640/messages', headers: headers, params: { page: 0 }

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Invalid page number')
      end

      pending 'responds with 400 if given page number is too large'

      it 'responds with 400 if given per page number is invalid' do
        get '/api/edesk/folders/20378640/messages', headers: headers, params: { per_page: '1x' }

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Invalid per page number')
      end

      it 'responds with 400 if given per page number is too small' do
        get '/api/edesk/folders/20378640/messages', headers: headers, params: { per_page: 9 }

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Per page number out of range')
      end

      it 'responds with 400 if given per page number is too large' do
        get '/api/edesk/folders/20378640/messages', headers: headers, params: { per_page: 5001 }

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Per page number out of range')
      end
    end

    include_examples 'API request media types', get: '/api/edesk/folders/20378640/messages', accept: 'application/json'
    include_examples 'API request authentication', get: '/api/edesk/folders/20378640/messages', allow_sub: true

    it 'responds with 400 if request contains invalid folder identifier' do
      get '/api/edesk/folders/0/messages', headers: headers

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'Invalid folder identifier')
    end

    pending 'responds with 404 if box is inaccessible (hides that it may exist)'

    it 'responds with 404 if box does not exist' do
      expect(upvs.eks).to receive(:get_messages).with(20378640, any_args).and_raise(eks_get_messages_fault('eks/get_messages/box_not_exist_fault.xml'))

      get '/api/edesk/folders/20378640/messages', headers: headers

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Box not found')
    end

    it 'responds with 404 if folder is inaccessible (hides that it may exist)' do
      expect(upvs.eks).to receive(:get_messages).with(20378640, any_args).and_raise(eks_get_messages_fault('eks/get_messages/folder_permission_denied_fault.xml'))

      get '/api/edesk/folders/20378640/messages', headers: headers

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Folder not found')
    end

    it 'responds with 404 if folder does not exist' do
      expect(upvs.eks).to receive(:get_messages).with(20378640, any_args).and_raise(eks_get_messages_fault('eks/get_messages/folder_permission_denied_fault.xml'))

      get '/api/edesk/folders/20378640/messages', headers: headers

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Folder not found')
    end

    it 'responds with 408 if EKR raises timeout error' do
      expect(upvs.eks).to receive(:get_messages).and_raise(soap_timeout_exception)

      get '/api/edesk/folders/20378640/messages', headers: headers

      expect(response.status).to eq(408)
      expect(response.object).to eq(message: 'Operation timeout exceeded')
    end

    it 'responds with 409 if box is not active' do
      expect(upvs.eks).to receive(:get_messages).with(20378640, any_args).and_raise(eks_get_messages_fault('eks/get_messages/box_inactive_fault.xml'))

      get '/api/edesk/folders/20378640/messages', headers: headers

      expect(response.status).to eq(409)
      expect(response.object).to eq(message: 'Box inactive')
    end

    pending 'responds with 429 if request rate limit exceeds'

    it 'responds with 500 if EKR raises internal error' do
      expect(upvs.eks).to receive(:get_messages).and_raise

      get '/api/edesk/folders/20378640/messages', headers: headers

      expect(response.status).to eq(500)
      expect(response.object).to eq(message: 'Unknown error')
    end

    it 'responds with 503 if EKR raises eDesk fault' do
      expect(upvs.eks).to receive(:get_messages).with(20378640, any_args).and_raise(eks_get_messages_fault('eks/general_fault.xml'))

      get '/api/edesk/folders/20378640/messages', headers: headers

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'EKR failure')
    end

    it 'responds with 503 if EKR raises SOAP fault' do
      expect(upvs.eks).to receive(:get_messages).and_raise(soap_fault_exception)

      get '/api/edesk/folders/20378640/messages', headers: headers

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'Unknown failure')
    end

    include_examples 'UPVS proxy initialization', get: '/api/edesk/folders/20378640/messages', allow_sub: true
  end

  describe 'GET /api/edesk/messages/search' do
    let(:filter) { org.datacontract.schemas._2004._07.anasoft_edesk_edeskii.Filter }

    def set_upvs_expectations
      expect(upvs.eks).to receive(:get_messages_by_filter).with(an_instance_of(filter), any_args).and_return(ekr_response('eks/filter_messages_response.xml').get_messages_by_filter_result.value)
    end

    it 'gets filtered messages' do
      set_upvs_expectations

      get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', headers: headers

      expect(response.status).to eq(200)
      expect(response.object).to eq(JSON.parse(file_fixture('api/edesk/search_messages.json').read, symbolize_names: true))
    end

    it 'raises if extra unpermitted filter' do
      expect(upvs.eks).not_to receive(:get_messages_by_filter)

      get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913&message_id=1a6a51c1-0754-x6c8-aac1-12465162b913', headers: headers

      expect(response.status).to eq(422)
      expect(response.object).to eq(message: 'Unpermitted parameters: ["message_id"]')
    end

    it 'raises if no filter' do
      get '/api/edesk/messages/search', headers: headers

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No correlation identifier')
    end

    context 'pagination' do
      it 'returns filtered messages at given page' do
        expect(upvs.eks).to receive(:get_messages_by_filter).with(an_instance_of(filter), 50, 200).and_return(ekr_response('eks/filter_messages_response.xml').get_messages_by_filter_result.value)

        get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', headers: headers, params: { page: 5 }

        expect(response.status).to eq(200)
      end

      it 'returns filtered messages at given page and with given per page' do
        expect(upvs.eks).to receive(:get_messages_by_filter).with(an_instance_of(filter), 25, 100).and_return(ekr_response('eks/filter_messages_response.xml').get_messages_by_filter_result.value)

        get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', headers: headers, params: { page: 5, per_page: 25 }

        expect(response.status).to eq(200)
      end

      it 'returns filtered messages with given per page' do
        expect(upvs.eks).to receive(:get_messages_by_filter).with(an_instance_of(filter), 25, 0).and_return(ekr_response('eks/filter_messages_response.xml').get_messages_by_filter_result.value)

        get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', headers: headers, params: { per_page: 25 }

        expect(response.status).to eq(200)
      end

      it 'responds with 400 if given page number is invalid' do
        get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', headers: headers, params: { page: '1x' }

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Invalid page number')
      end

      it 'responds with 400 if given page number is zero' do
        get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', headers: headers, params: { page: 0 }

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Invalid page number')
      end

      pending 'responds with 400 if given page number is too large'

      it 'responds with 400 if given per page number is invalid' do
        get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', headers: headers, params: { per_page: '1x' }

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Invalid per page number')
      end

      it 'responds with 400 if given per page number is too small' do
        get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', headers: headers, params: { per_page: 9 }

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Per page number out of range')
      end

      it 'responds with 400 if given per page number is too large' do
        get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', headers: headers, params: { per_page: 5001 }

        expect(response.status).to eq(400)
        expect(response.object).to eq(message: 'Per page number out of range')
      end
    end

    include_examples 'API request media types', get: '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', accept: 'application/json'

    context 'a' do
      include_examples 'API request authentication', get: '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', allow_sub: true
    end

    it 'responds with 400 if request contains invalid correlation ID' do
      get '/api/edesk/messages/search?correlation_id=123', headers: headers

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'Invalid correlation identifier')
    end

    pending 'responds with 404 if box is inaccessible (hides that it may exist)'

    it 'responds with 404 if box does not exist' do
      expect(upvs.eks).to receive(:get_messages_by_filter).with(an_instance_of(filter), any_args).and_raise(eks_get_messages_fault('eks/get_messages/box_not_exist_fault.xml'))

      get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', headers: headers

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Box not found')
    end

    it 'responds with 408 if EKR raises timeout error' do
      expect(upvs.eks).to receive(:get_messages_by_filter).with(an_instance_of(filter), any_args).and_raise(soap_timeout_exception)

      get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', headers: headers

      expect(response.status).to eq(408)
      expect(response.object).to eq(message: 'Operation timeout exceeded')
    end

    it 'responds with 409 if box is not active' do
      expect(upvs.eks).to receive(:get_messages_by_filter).with(an_instance_of(filter), any_args).and_raise(eks_get_messages_fault('eks/get_messages/box_inactive_fault.xml'))

      get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', headers: headers

      expect(response.status).to eq(409)
      expect(response.object).to eq(message: 'Box inactive')
    end

    pending 'responds with 429 if request rate limit exceeds'

    it 'responds with 500 if EKR raises internal error' do
      expect(upvs.eks).to receive(:get_messages_by_filter).with(an_instance_of(filter), any_args).and_raise

      get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', headers: headers

      expect(response.status).to eq(500)
      expect(response.object).to eq(message: 'Unknown error')
    end

    it 'responds with 503 if EKR raises eDesk fault' do
      expect(upvs.eks).to receive(:get_messages_by_filter).with(an_instance_of(filter), any_args).and_raise(eks_get_messages_fault('eks/general_fault.xml'))

      get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', headers: headers

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'EKR failure')
    end

    it 'responds with 503 if EKR raises SOAP fault' do
      expect(upvs.eks).to receive(:get_messages_by_filter).with(an_instance_of(filter), any_args).and_raise(soap_fault_exception)

      get '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', headers: headers

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'Unknown failure')
    end

    include_examples 'UPVS proxy initialization', get: '/api/edesk/messages/search?correlation_id=8a6a31c1-0d54-46c8-aac1-12465162b913', allow_sub: true
  end

  describe 'GET /api/edesk/messages/{id}' do
    def set_upvs_expectations
      expect(upvs.eks).to receive(:get_message).with(4898662475).and_return(ekr_response('eks/get_message_response.xml').get_message_result.value)
    end

    it 'gets message' do
      set_upvs_expectations

      get '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(200)
      expect(response.object).to eq(JSON.parse(file_fixture('api/edesk/message.json').read, symbolize_names: true))
    end

    it 'gets message with delivery notification' do
      expect(upvs.eks).to receive(:get_message).with(4898663168).and_return(ekr_response('eks/get_message/class/ed_delivery_notification_response.xml').get_message_result.value)

      get '/api/edesk/messages/4898663168', headers: headers

      expect(response.status).to eq(200)
      expect(response.object).to eq(JSON.parse(file_fixture('api/edesk/message/delivery_notification.json').read, symbolize_names: true))
    end

    context 'eDesk message parser' do
      fixture_names('eks/get_message/class/*.xml').each do |fixture|
        it "gets #{fixture_name_to_human(fixture)} message without parse error" do
          expect(upvs.eks).to receive(:get_message).with(1).and_return(ekr_response(fixture).get_message_result.value)

          get '/api/edesk/messages/1', headers: headers

          expect(response.status).to eq(200)
          expect(response.object[:parse_error]).to eq(false)
        end
      end
    end

    include_examples 'API request media types', get: '/api/edesk/messages/4898662475', accept: 'application/json'
    include_examples 'API request authentication', get: '/api/edesk/messages/4898662475', allow_sub: true

    it 'responds with 400 if request contains invalid message identifier' do
      get '/api/edesk/messages/0', headers: headers

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'Invalid message identifier')
    end

    pending 'responds with 404 if box is inaccessible (hides that it may exist)'

    it 'responds with 404 if box does not exist' do
      expect(upvs.eks).to receive(:get_message).with(4898662475).and_raise(eks_get_message_fault('eks/get_message/box_not_exist_fault.xml'))

      get '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Box not found')
    end

    it 'responds with 404 if message is inaccessible (hides that it may exist)' do
      expect(upvs.eks).to receive(:get_message).with(4898662475).and_raise(eks_get_message_fault('eks/get_message/message_permission_denied_fault.xml'))

      get '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Message not found')
    end

    it 'responds with 404 if message does not exist' do
      expect(upvs.eks).to receive(:get_message).with(4898662475).and_return(ekr_response('eks/get_message/no_message_response.xml').get_message_result.value)

      get '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Message not found')
    end

    it 'responds with 408 if EKR raises timeout error' do
      expect(upvs.eks).to receive(:get_message).and_raise(soap_timeout_exception)

      get '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(408)
      expect(response.object).to eq(message: 'Operation timeout exceeded')
    end

    it 'responds with 409 if box is not active' do
      expect(upvs.eks).to receive(:get_message).with(4898662475).and_raise(eks_get_message_fault('eks/get_message/box_inactive_fault.xml'))

      get '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(409)
      expect(response.object).to eq(message: 'Box inactive')
    end

    pending 'responds with 429 if request rate limit exceeds'

    it 'responds with 500 if EKR raises internal error' do
      expect(upvs.eks).to receive(:get_message).and_raise

      get '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(500)
      expect(response.object).to eq(message: 'Unknown error')
    end

    it 'responds with 503 if EKR raises eDesk fault' do
      expect(upvs.eks).to receive(:get_message).with(4898662475).and_raise(eks_get_message_fault('eks/general_fault.xml'))

      get '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'EKR failure')
    end

    it 'responds with 503 if EKR raises SOAP fault' do
      expect(upvs.eks).to receive(:get_message).and_raise(soap_fault_exception)

      get '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'Unknown failure')
    end

    include_examples 'UPVS proxy initialization', get: '/api/edesk/messages/4898662475', allow_sub: true
  end

  describe 'PATCH /api/edesk/messages/{id}' do
    let(:params) do
      { folder_id: 20378640 }
    end

    def set_upvs_expectations
      expect(upvs.eks).to receive(:move_message).with(4898662475, 20378640).and_return(nil)
    end

    it 'moves message' do
      set_upvs_expectations

      patch '/api/edesk/messages/4898662475', headers: headers, params: params, as: :json

      expect(response.status).to eq(204)
      expect(response.body).to be_empty
    end

    include_examples 'API request media types', patch: '/api/edesk/messages/4898662475', accept: 'application/json', expect_response_body: false
    include_examples 'API request authentication', patch: '/api/edesk/messages/4898662475', allow_sub: true

    it 'responds with 400 if request does not contain folder identifier' do
      patch '/api/edesk/messages/4898662475', headers: headers, params: params.except(:folder_id), as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No folder identifier')
    end

    it 'responds with 400 if request contains invalid folder identifier' do
      patch '/api/edesk/messages/4898662475', headers: headers, params: params.merge(folder_id: 0), as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'Invalid folder identifier')
    end

    it 'responds with 400 if request contains invalid message identifier' do
      patch '/api/edesk/messages/0', headers: headers, params: params, as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'Invalid message identifier')
    end

    pending 'responds with 404 if box is inaccessible (hides that it may exist)'

    it 'responds with 404 if box does not exist' do
      expect(upvs.eks).to receive(:move_message).with(4898662475, 20378640).and_raise(eks_move_message_fault('eks/move_message/box_not_exist_fault.xml'))

      patch '/api/edesk/messages/4898662475', headers: headers, params: params, as: :json

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Box not found')
    end

    it 'responds with 404 if folder is inaccessible (hides that it may exist)' do
      expect(upvs.eks).to receive(:move_message).with(4898662475, 20378640).and_raise(eks_move_message_fault('eks/move_message/folder_permission_denied_fault.xml'))

      patch '/api/edesk/messages/4898662475', headers: headers, params: params, as: :json

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Folder not found')
    end

    it 'responds with 404 if message is inaccessible (hides that it may exist)' do
      expect(upvs.eks).to receive(:move_message).with(4898662475, 20378640).and_raise(eks_move_message_fault('eks/move_message/message_permission_denied_fault.xml'))

      patch '/api/edesk/messages/4898662475', headers: headers, params: params, as: :json

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Message not found')
    end

    it 'responds with 404 if folder does not exist' do
      expect(upvs.eks).to receive(:move_message).with(4898662475, 20378640).and_raise(eks_move_message_fault('eks/move_message/folder_not_exist_fault.xml'))

      patch '/api/edesk/messages/4898662475', headers: headers, params: params, as: :json

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Folder not found')
    end

    it 'responds with 404 if message does not exist' do
      expect(upvs.eks).to receive(:move_message).with(4898662475, 20378640).and_raise(eks_move_message_fault('eks/move_message/message_not_exist_fault.xml'))

      patch '/api/edesk/messages/4898662475', headers: headers, params: params, as: :json

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Message not found')
    end

    it 'responds with 408 if EKR raises timeout error' do
      expect(upvs.eks).to receive(:move_message).and_raise(soap_timeout_exception)

      patch '/api/edesk/messages/4898662475', headers: headers, params: params, as: :json

      expect(response.status).to eq(408)
      expect(response.object).to eq(message: 'Operation timeout exceeded')
    end

    it 'responds with 409 if box is not active' do
      expect(upvs.eks).to receive(:move_message).with(4898662475, 20378640).and_raise(eks_move_message_fault('eks/move_message/box_inactive_fault.xml'))

      patch '/api/edesk/messages/4898662475', headers: headers, params: params, as: :json

      expect(response.status).to eq(409)
      expect(response.object).to eq(message: 'Box inactive')
    end

    pending 'responds with 429 if request rate limit exceeds'

    it 'responds with 500 if something fails' do
      expect(upvs.eks).to receive(:move_message).and_raise

      patch '/api/edesk/messages/4898662475', headers: headers, params: params, as: :json

      expect(response.status).to eq(500)
      expect(response.object).to eq(message: 'Unknown error')
    end

    it 'responds with 503 if EKR raises eDesk fault' do
      expect(upvs.eks).to receive(:move_message).with(4898662475, 20378640).and_raise(eks_move_message_fault('eks/general_fault.xml'))

      patch '/api/edesk/messages/4898662475', headers: headers, params: params, as: :json

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'EKR failure')
    end

    it 'responds with 503 if EKR raises SOAP fault' do
      expect(upvs.eks).to receive(:move_message).and_raise(soap_fault_exception)

      patch '/api/edesk/messages/4898662475', headers: headers, params: params, as: :json

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'Unknown failure')
    end

    include_examples 'UPVS proxy initialization', patch: '/api/edesk/messages/4898662475', allow_sub: true
  end

  describe 'DELETE /api/edesk/messages/{id}' do
    def set_upvs_expectations
      expect(upvs.eks).to receive(:delete_message).with(4898662475).and_return(ekr_response('eks/delete_message_response.xml').is_delete_message_result)
    end

    it 'deletes message' do
      set_upvs_expectations

      delete '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(204)
      expect(response.body).to be_empty
    end

    include_examples 'API request media types', delete: '/api/edesk/messages/4898662475', accept: 'application/json', expect_response_body: false
    include_examples 'API request authentication', delete: '/api/edesk/messages/4898662475', allow_sub: true

    it 'responds with 400 if request contains invalid message identifier' do
      delete '/api/edesk/messages/0', headers: headers

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'Invalid message identifier')
    end

    pending 'responds with 404 if box is inaccessible (hides that it may exist)'

    it 'responds with 404 if box does not exist' do
      expect(upvs.eks).to receive(:delete_message).with(4898662475).and_raise(eks_delete_message_fault('eks/delete_message/box_not_exist_fault.xml'))

      delete '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Box not found')
    end

    it 'responds with 404 if message is inaccessible (hides that it may exist)' do
      expect(upvs.eks).to receive(:delete_message).with(4898662475).and_raise(eks_delete_message_fault('eks/delete_message/message_permission_denied_fault.xml'))

      delete '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Message not found')
    end

    it 'responds with 204 if message does not exist' do
      expect(upvs.eks).to receive(:delete_message).with(4898662475).and_return(ekr_response('eks/delete_message/no_message_response.xml').is_delete_message_result)

      delete '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(204)
      expect(response.body).to be_empty
    end

    it 'responds with 408 if EKR raises timeout error' do
      expect(upvs.eks).to receive(:delete_message).and_raise(soap_timeout_exception)

      delete '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(408)
      expect(response.object).to eq(message: 'Operation timeout exceeded')
    end

    it 'responds with 409 if box is not active' do
      expect(upvs.eks).to receive(:delete_message).with(4898662475).and_raise(eks_delete_message_fault('eks/delete_message/box_inactive_fault.xml'))

      delete '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(409)
      expect(response.object).to eq(message: 'Box inactive')
    end

    pending 'responds with 429 if request rate limit exceeds'

    it 'responds with 500 if EKR raises internal error' do
      expect(upvs.eks).to receive(:delete_message).and_raise

      delete '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(500)
      expect(response.object).to eq(message: 'Unknown error')
    end

    it 'responds with 503 if EKR raises eDesk fault' do
      expect(upvs.eks).to receive(:delete_message).with(4898662475).and_raise(eks_delete_message_fault('eks/general_fault.xml'))

      delete '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'EKR failure')
    end

    it 'responds with 503 if EKR raises SOAP fault' do
      expect(upvs.eks).to receive(:delete_message).and_raise(soap_fault_exception)

      delete '/api/edesk/messages/4898662475', headers: headers

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'Unknown failure')
    end

    include_examples 'UPVS proxy initialization', delete: '/api/edesk/messages/4898662475', allow_sub: true
  end

  describe 'POST /api/edesk/messages/{id}/authorize' do
    def set_upvs_expectations
      expect(upvs.eks).to receive(:confirm_notification_report).with(4898663168).and_return(ekr_response('eks/confirm_notification_report_response.xml'))
    end

    it 'authorizes message' do
      set_upvs_expectations

      post '/api/edesk/messages/4898663168/authorize', headers: headers

      expect(response.status).to eq(200)
      expect(response.object.keys).to contain_exactly(:authorized_message_id)
    end

    include_examples 'API request media types', post: '/api/edesk/messages/4898663168/authorize', accept: 'application/json', require_request_body: false
    include_examples 'API request authentication', post: '/api/edesk/messages/4898663168/authorize', allow_sub: true

    it 'responds with 400 if request contains invalid message identifier' do
      post '/api/edesk/messages/0/authorize', headers: headers

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'Invalid message identifier')
    end

    pending 'responds with 404 if box is inaccessible (hides that it may exist)'

    pending 'responds with 404 if box does not exist'

    it 'responds with 404 if message is inaccessible (hides that it may exist)' do
      expect(upvs.eks).to receive(:confirm_notification_report).with(4898663168).and_raise(eks_authorize_message_fault('eks/authorize_message/message_permission_denied_fault.xml'))

      post '/api/edesk/messages/4898663168/authorize', headers: headers

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Message not found')
    end

    it 'responds with 404 if message does not exist' do
      expect(upvs.eks).to receive(:confirm_notification_report).with(4898663168).and_raise(eks_authorize_message_fault('eks/authorize_message/no_message_fault.xml'))

      post '/api/edesk/messages/4898663168/authorize', headers: headers

      expect(response.status).to eq(404)
      expect(response.object).to eq(message: 'Message not found')
    end

    it 'responds with 408 if EKR raises timeout error' do
      expect(upvs.eks).to receive(:confirm_notification_report).with(4898663168).and_raise(soap_timeout_exception)

      post '/api/edesk/messages/4898663168/authorize', headers: headers

      expect(response.status).to eq(408)
      expect(response.object).to eq(message: 'Operation timeout exceeded')
    end

    pending 'responds with 409 if box is not active'

    pending 'responds with 429 if request rate limit exceeds'

    it 'responds with 422 if message does not contain delivery notification' do
      expect(upvs.eks).to receive(:confirm_notification_report).with(4898662475).and_raise(eks_authorize_message_fault('eks/authorize_message/non_delivery_notification_fault.xml'))

      post '/api/edesk/messages/4898662475/authorize', headers: headers

      expect(response.status).to eq(422)
      expect(response.object).to eq(message: 'Cannot authorize non-notification report message')
    end

    it 'responds with 422 if notification report has already been authorized' do
      expect(upvs.eks).to receive(:confirm_notification_report).with(4898662475).and_raise(eks_authorize_message_fault('eks/authorize_message/already_authorized_fault.xml'))

      post '/api/edesk/messages/4898662475/authorize', headers: headers

      expect(response.status).to eq(422)
      expect(response.object).to eq(message: 'The notification report has already been confirmed')
    end

    it 'responds with 500 if EKR raises internal error' do
      expect(upvs.eks).to receive(:confirm_notification_report).with(4898663168).and_raise

      post '/api/edesk/messages/4898663168/authorize', headers: headers

      expect(response.status).to eq(500)
      expect(response.object).to eq(message: 'Unknown error')
    end

    it 'responds with 503 if EKR raises eDesk fault' do
      expect(upvs.eks).to receive(:confirm_notification_report).with(4898663168).and_raise(eks_authorize_message_fault('eks/general_fault.xml'))

      post '/api/edesk/messages/4898663168/authorize', headers: headers

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'EKR failure')
    end

    it 'responds with 503 if EKR raises SOAP fault' do
      expect(upvs.eks).to receive(:confirm_notification_report).and_raise(soap_fault_exception)

      post '/api/edesk/messages/4898663168/authorize', headers: headers

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'Unknown failure')
    end

    it 'responds with 503 if EKR raises SOAP fault with UPVS code' do
      expect(upvs.eks).to receive(:confirm_notification_report).with(4898663168).and_raise(soap_fault_exception('00000000'))

      post '/api/edesk/messages/4898663168/authorize', headers: headers

      expect(response.status).to eq(503)
      expect(response.object).to eq(message: 'Unknown failure', fault: { code: '00000000' })
    end

    include_examples 'UPVS proxy initialization', post: '/api/edesk/messages/4898663168/authorize', allow_sub: true
  end
end
