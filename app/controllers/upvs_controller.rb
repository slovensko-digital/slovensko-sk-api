class UpvsController < ApiController
  # TODO add support for more callback urls (get from param -> check against env -> store in session -> redirect on success)

  def login
    redirect_to url_for('/auth/saml')
  end

  def callback
    response = request.env['omniauth.auth']['extra']['response_object']
    scopes = ['sktalk/receive', 'sktalk/receive_and_save_to_outbox']
    token = Environment.obo_token_authenticator.generate_token(response, scopes: scopes)

    redirect_to login_callback_url(token)
  end

  # TODO add authentication check before initiating SP logout
  # Environment.api_token_authenticator.invalidate_token(authenticity_token, obo: true)
  # redirect_to logout_callback_url

  def logout
    if params[:SAMLRequest]
      redirect_to "/auth/saml/slo?#{params.permit(:SAMLRequest, :SigAlg, :Signature).to_query}"
    elsif params[:SAMLResponse]
      redirect_to "/auth/saml/slo?#{params.permit(:SAMLResponse, :SigAlg, :Signature).to_query}"
    else
      redirect_to '/auth/saml/spslo'
    end
  end

  private

  def login_callback_url(token)
    "#{Environment.login_callback_url}?token=#{token}"
  end

  def logout_callback_url
    Environment.logout_callback_url
  end
end
