class UpvsController < ApplicationController

  # TODO
  # protect_from_forgery with: :exception
  # skip_before_action :verify_authenticity_token

  def login
  end

  def callback
    decrypted_document = auth['extra']['response_object'].decrypted_document
    assertion = REXML::XPath.first(decrypted_document, '//saml:Assertion')

    UpvsEnvironment.assertion_store.write(session[:key] = SecureRandom.uuid, assertion.to_s)

    render json: session[:key]
  end

  def logout
  end

  private

  def auth
    request.env['omniauth.auth']
  end
end
