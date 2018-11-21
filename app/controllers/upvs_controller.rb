class UpvsController < ApplicationController
  def login
    redirect_to url_for('/auth/saml')
  end

  def callback
    response = request.env['omniauth.auth']['extra']['response_object']
    token = authenticator.generate_token(response)

    render status: :ok, json: { message: 'Signed in', token: token }
  end

  def logout
    if params[:token].present?
      authenticator.invalidate_token(params[:token])

      reset_session # TODO ???

      render status: :ok, json: { message: 'Signed out' }
    else
      render_bad_request('No credentials')
    end

    # TODO rewrite this: logout via IDP works, logout via SP signs out here but user remains signed in at IDP
    # if params[:SAMLResponse]
    #   UpvsEnvironment.assertion_store.delete(params[:key])
    #
    #   render status: :ok, json: { message: 'Signed out' }
    # else
    #   redirect_to url_for('/auth/saml/spslo')
    # end
  end
end
