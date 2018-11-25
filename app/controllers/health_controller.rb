class HealthController < ApplicationController
  def index
    render status: :ok, json: { status: :ok }
  end
end
