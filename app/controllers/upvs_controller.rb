class UpvsController < ApplicationController
  skip_before_action :verify_authenticity_token

  # TODO add support for more callback urls (get from param -> check against env -> store in session -> redirect on success)

  def login
    redirect_to url_for('/auth/saml')
  end

  def callback
    response = request.env['omniauth.auth']['extra']['response_object']
    token = authenticator.generate_token(response, scopes: ['sktalk:receive', 'sktalk:receive_and_save_to_outbox'])

    redirect_to login_callback_url(token)
  end

  # TODO do we want API tokens or UPVS tokens on logout?

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
    UpvsEnvironment.token_authenticator
  end

  def login_callback_url(token)
    "#{ApiEnvironment.login_callback_url}?token=#{token}"
  end

  def logout_callback_url
    ApiEnvironment.logout_callback_url
  end
end
