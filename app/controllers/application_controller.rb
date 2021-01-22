# TODO drop this and rename ApiController to ApplicationController

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end
