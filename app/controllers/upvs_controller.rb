class UpvsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def login
  end

  def callback
  end

  def logout
  end

  protected

  def auth_hash
    request.env['omniauth.auth']
  end
end
