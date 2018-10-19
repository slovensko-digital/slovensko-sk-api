class SktalkController < ApplicationController
  def receive
    if params[:message].present?
      render status: :ok, json: { message: '<xml>' }
    else
      render status: :bad_request, json: { error: 'Missing SKTalk message' }
    end
  end
end
