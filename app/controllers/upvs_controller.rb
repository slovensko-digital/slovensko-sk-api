class UpvsController < ApiController
  skip_before_action(:verify_request_body, except: :assertion)
  skip_before_action(:verify_format)

  before_action(only: :assertion) { respond_to(:saml) }

  def login
    session[:login_callback_url] = fetch_callback_url(Environment.login_callback_urls)

    redirect_to '/auth/saml'
  end

  def callback
    response = request.env['omniauth.auth']['extra']['response_object']
    token = Environment.obo_token_authenticator.generate_token(response, scopes: Environment.obo_token_scopes)

    redirect_to callback_url_with_token(session[:login_callback_url], token)
  end

  def assertion
    _, assertion = Environment.api_token_authenticator.verify_token(authenticity_token, allow_obo_token: true)

    render content_type: Mime[:saml], plain: assertion
  end

  def logout
    if params[:SAMLRequest]
      redirect_to "/auth/saml/slo?#{slo_request_params.to_query}"
    elsif params[:SAMLResponse]
      redirect_to "/auth/saml/slo?#{slo_response_params(session[:logout_callback_url]).to_query}"
    else
      Environment.api_token_authenticator.invalidate_token(authenticity_token, allow_obo_token: true)
      session[:logout_callback_url] = fetch_callback_url(Environment.logout_callback_urls)

      redirect_to '/auth/saml/spslo'
    end
  end

  include CallbackHelper

  CallbackError = Class.new(StandardError)

  rescue_from(CallbackError) { |error| render_bad_request(error.message, :callback) }

  private

  def fetch_callback_url(registered_urls)
    raise CallbackError, :missing if params[:callback].blank?
    raise CallbackError, :invalid if registered_urls.none? { |url| callback_match?(url, params[:callback]) }
    params[:callback]
  rescue URI::Error
    raise CallbackError, :invalid
  end

  def callback_url_with_token(callback_url, token)
    URI(callback_url).tap { |url| url.query = [url.query, "token=#{token}"].compact.join('&') }.to_s
  end

  def slo_request_params
    params.permit(:SAMLRequest, :SigAlg, :Signature)
  end

  def slo_response_params(redirect_url)
    params.permit(:SAMLResponse, :SigAlg, :Signature).merge(RelayState: redirect_url)
  end
end
