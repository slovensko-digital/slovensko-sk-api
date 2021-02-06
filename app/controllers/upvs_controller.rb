class UpvsController < ApiController
  skip_before_action(:verify_request_body, except: [:assertion, :identity])
  skip_before_action(:verify_format, except: :identity)

  before_action(only: :assertion) { respond_to(:saml) }
  before_action(only: [:assertion, :identity]) { authenticate(allow_obo_token: true, require_obo_token_scope: action_scope) }

  def login
    session[:login_callback_url] = fetch_callback_url(Environment.login_callback_urls)

    redirect_to '/auth/saml'
  end

  def callback
    response = request.env['omniauth.auth']['extra']['response_object']
    token = Environment.obo_token_authenticator.generate_token(response, scopes: Environment.obo_token_scopes)

    redirect_to callback_url_with_token(session[:login_callback_url], token)
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

  def assertion
    render content_type: Mime[:saml], plain: upvs_identity[:obo]
  end

  def identity
    render partial: 'iam/identity', locals: { identity: iam_repository(upvs_identity).identity(obo_subject_id(upvs_identity[:obo])) }
  end

  include CallbackHelper

  CallbackError = Class.new(StandardError)

  rescue_from(CallbackError) { |error| render_bad_request(error.message, :callback) }

  rescue_from(sk.gov.schemas.identity.service._1_7.GetIdentityFault) { |error| render_bad_request(:invalid, :identity_id, upvs_fault(error)) }

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

  def obo_subject_id(assertion)
    Nokogiri::XML(assertion).at_xpath('//saml:Attribute[@Name="SubjectID"]/saml:AttributeValue').content
  end
end
