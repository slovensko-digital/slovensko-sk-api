class UpvsController < ApplicationController

  # TODO
  # protect_from_forgery with: :exception
  # skip_before_action :verify_authenticity_token

  def login
  end

  def callback
    response = Nokogiri::XML.parse(auth['extra']['response_object'].response)
    assertion = response.xpath('//saml:Assertion').first
    namespaces = response.namespaces.slice('xmlns:saml', 'xmlns:dsig', 'xmlns:xsi')
    namespaces.each { |namespace, name| assertion[namespace] = name }

    UpvsEnvironment.assertion_store.write(session[:key] = SecureRandom.uuid, assertion.to_xml)

    render xml: assertion
  end

  def logout
  end

  private

  def auth
    request.env['omniauth.auth']
  end
end
