class UpvsController < ApplicationController
  # TODO
  # protect_from_forgery with: :exception
  # skip_before_action :verify_authenticity_token

  before_action(only: :login) { render_bad_request('Already signed in') if session[:key] }
  before_action(only: :logout) { render_bad_request('Already signed out') unless session[:key] }

  def login
    redirect_to url_for('/auth/saml')
  end

  def callback
    response = Nokogiri::XML.parse(auth['extra']['response_object'].response)
    assertion = response.xpath('//saml:Assertion').first
    namespaces = response.namespaces.slice('xmlns:saml', 'xmlns:dsig', 'xmlns:xsi')
    namespaces.each { |namespace, name| assertion[namespace] = name }

    UpvsEnvironment.assertion_store.write(session[:key] = SecureRandom.uuid, assertion.to_xml)

    render status: :ok, json: { message: 'Signed in' }
  end

  def logout
    # TODO check notes in omniauth_saml first, then update this:

    if params[:SAMLResponse]
      UpvsEnvironment.assertion_store.delete(session[:key])

      session[:key] = nil

      render status: :ok, json: { message: 'Signed out' }
    else
      redirect_to url_for('/auth/saml/spslo')
    end
  end

  private

  def auth
    request.env['omniauth.auth']
  end
end
