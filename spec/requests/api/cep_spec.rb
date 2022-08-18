require 'rails_helper'

RSpec.describe 'CEP API' do
  allow_api_token_with_obo_token!
  skip_upvs_subject_verification!

  let(:token) { api_token_with_subject }
  let(:upvs) { upvs_proxy_double }

  describe 'POST /api/cep/signatures_info' do
    let(:params) do
      {
        content: file_fixture('cep/general_agenda.asice_xades.base64').read
      }
    end

    let(:ez_service) { sk.gov.schemas.servicebus.service._1.ServiceClassEnum::DITEC_CEP_ZISTI_TYP_A_FORMU_PODPISU_2 }
    let(:ez_request_class) { sk.gov.schemas.servicebusserviceprovider.ditec.cepprovider._1.ZistiTypAFormuPodpisu2Req }
    let(:ez_response_class) { sk.gov.schemas.servicebusserviceprovider.ditec.cepprovider._1.ZistiTypAFormuPodpisu2Res }

    def set_upvs_expectations
      expect(upvs.ez).to receive(:call_service).with(ez_service, kind_of(ez_request_class)).and_return(usr_service_result('ez/cep/zisti_typ_a_formu_podpisu/response_signed.xml'))
    end

    context 'returns info about signatures' do
      it 'signed document' do
        set_upvs_expectations

        post '/api/cep/signatures_info', headers: headers, params: params, as: :json

        expect(response.status).to eq(200)
        expect(response.object[:is_signed]).to eq(true)
        expect(response.object[:description]).to eq('OK')
        expect(response.object[:mime_type]).to eq('application/vnd.etsi.asic-e+zip')
        expect(response.object[:signatures].first[:type]).to eq('XadesBPLevelT')
        expect(response.object[:signatures].first[:format]).to eq('XAdES-BP')
        expect(response.object[:signatures].first[:with_timestamp]).to eq(true)
      end

      it 'unsigned document' do
        params = {
          content: Base64.strict_encode64(file_fixture('cep/general_agenda.xml').read)
        }

        expect(upvs.ez).to receive(:call_service).with(ez_service, kind_of(ez_request_class)).and_return(usr_service_result('ez/cep/zisti_typ_a_formu_podpisu/response_unsigned.xml'))

        post '/api/cep/signatures_info', headers: headers, params: params, as: :json

        expect(response.status).to eq(200)
        expect(response.object[:is_signed]).to eq(false)
        expect(response.object[:description]).to eq('Vstupné dáta neobsahujú podpis alebo obsahujú nepodporovaný typ podpisu')
      end
    end

    include_examples 'API request media types', post: '/api/cep/signatures_info', accept: 'application/json'
    include_examples 'API request authentication', post: '/api/cep/signatures_info', allow_sub: true

    it 'responds with 400 if request does not contain content' do
      post '/api/cep/signatures_info', headers: headers, params: params.except(:content), as: :json

      expect(response.status).to eq(400)
      expect(response.object).to eq(message: 'No content')
    end

    pending 'responds with 400 if request contains invalid parameters' # TODO

    include_examples 'USR request timeout', post: '/api/cep/signatures_info'

    pending 'responds with 413 if payload is too large'

    pending 'responds with 429 if request rate limit exceeds'

    include_examples 'USR request failure', post: '/api/cep/signatures_info'
    include_examples 'UPVS proxy initialization', post: '/api/cep/signatures_info', allow_sub: true
  end
end
