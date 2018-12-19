class UpvsController < ApiController
  def login
    redirect_to '/auth/saml'
  end

  def callback
    response = request.env['omniauth.auth']['extra']['response_object']
    scopes = ['sktalk/receive', 'sktalk/receive_and_save_to_outbox']
    token = Environment.obo_token_authenticator.generate_token(response, scopes: scopes)

    redirect_to "#{login_callback_url}?token=#{token}"
  end

  def logout
    if params[:SAMLRequest]
      redirect_to "/auth/saml/slo?#{slo_request_params.to_query}"
    elsif params[:SAMLResponse]
      redirect_to "/auth/saml/slo?#{slo_response_params(logout_callback_url).to_query}"
    else
      Environment.api_token_authenticator.invalidate_token(authenticity_token, obo: true)

      redirect_to '/auth/saml/spslo'
    end
  end

  private

  # TODO add support for more callback urls (get from param -> check against env -> store in session -> redirect on success)

  def login_callback_url
    Environment.login_callback_url
  end

  def logout_callback_url
    Environment.logout_callback_url
  end

  def slo_request_params
    params.permit(:SAMLRequest, :SigAlg, :Signature)
  end

  def slo_response_params(redirect_url)
    params.permit(:SAMLResponse, :SigAlg, :Signature).merge(RelayState: redirect_url)
  end
end
