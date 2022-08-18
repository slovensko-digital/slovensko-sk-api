class CepController < ApiController
  before_action { authenticate(allow_sub: true) }

  def signatures_info
    content = params.require(:content)

    @response = cep_signer(upvs_identity).signatures_info(content)
  end
end
