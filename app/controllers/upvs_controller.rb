class UpvsController < ApiController
  skip_before_action(:verify_request_body, except: [:assertion, :identity])
  skip_before_action(:verify_format, except: :identity)

  before_action(only: :assertion) { respond_to(:saml) }
  before_action(only: [:assertion, :identity]) { authenticate(allow_obo_token: true, require_obo_token_scope: action_scope) }

  def login
    redirect_to '/auth/saml'
  end

  def callback
    response = request.env['omniauth.auth']['extra']['response_object']
    token = Environment.obo_token_authenticator.generate_token(response, scopes: Environment.obo_token_scopes)

    redirect_to callback_url_with_token(Environment.login_callback_url, token)
  end

  def logout
    if params[:SAMLRequest]
      redirect_to callback_url_with_sp_callback(Environment.logout_callback_url)
    elsif params[:SAMLResponse]
      redirect_to "/auth/saml/slo?#{slo_response_params(Environment.logout_callback_url).to_query}"
    else
      Environment.api_token_authenticator.invalidate_token(authenticity_token, allow_obo_token: true)

      redirect_to '/auth/saml/spslo'
    end
  end

  def assertion
    render content_type: Mime[:saml], plain: upvs_identity[:obo]
  end

  def identity
    render partial: 'iam/identity', locals: { identity: iam_repository(upvs_identity).identity(obo_subject_id(upvs_identity[:obo])) }
  end

  rescue_from(sk.gov.schemas.identity.service._1_7.GetIdentityFault) { |error| render_bad_request(:invalid, :identity_id, upvs_fault(error)) }

  private

  def callback_url_with_token(callback_url, token)
    URI(callback_url).tap { |url| url.query = [url.query, "token=#{token}"].compact.join('&') }.to_s
  end

  def callback_url_with_sp_callback(callback_url)
    uri = URI.parse(callback_url)
    params = URI.decode_www_form(uri.query || '') + {'callback': slo_callback}.to_a
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  def slo_request_params
    params.permit(:SAMLRequest, :SigAlg, :Signature)
  end

  def slo_response_params(redirect_url)
    params.permit(:SAMLResponse, :SigAlg, :Signature).merge(RelayState: redirect_url)
  end

  def slo_callback
    "#{request.protocol + request.host_with_port}/auth/saml/slo?#{slo_request_params.to_query}"
  end

  def obo_subject_id(assertion)
    Nokogiri::XML(assertion).at_xpath('//saml:Attribute[@Name="SubjectID"]/saml:AttributeValue').content
  end
end
