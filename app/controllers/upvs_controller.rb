class UpvsController < ApplicationController
  def login
    redirect_to url_for('/auth/saml')
  end

  def callback
    response = request.env['omniauth.auth']['extra']['response_object']
    token = authenticator.generate_token(response)

    redirect_to login_callback_url(token)
  end

  def logout
    authenticator.invalidate_token(params[:token])

    redirect_to logout_callback_url

    # TODO rewrite this: logout via IDP works, logout via SP signs out here but user remains signed in at IDP
    # if params[:SAMLResponse]
    #   UpvsEnvironment.assertion_store.delete(params[:key])
    #
    #   render status: :ok, json: { message: 'Signed out' }
    # else
    #   redirect_to url_for('/auth/saml/spslo')
    # end
  end

  private

  def authenticator
    ApiEnvironment.token_authenticator
  end

  def login_callback_url(token)
    "#{ApiEnvironment.login_callback_url}?token=#{token}"
  end

  def logout_callback_url
    ApiEnvironment.logout_callback_url
  end
end
