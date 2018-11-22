# TODO rm: do not forget to remove TP_JWT_PRIVATE_KEY env variable when removing this file

class TpController < ApplicationController

  # this simulates 3rd party callback by generating signed API token from received OBO token :)

  def callback
    obo_token = params['token']

    payload = { obo: obo_token }
    private_key = OpenSSL::PKey::RSA.new(Base64.decode64(ENV.fetch('API_TOKEN_PRIVATE_KEY')))

    api_token = JWT.encode(payload, private_key, 'RS256')

    render status: :ok, json: { api_token: api_token, obo_token: obo_token }
  end
end
