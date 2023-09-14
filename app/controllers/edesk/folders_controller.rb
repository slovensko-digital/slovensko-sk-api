class Edesk::FoldersController < ApiController
  include EdeskRescuable

  before_action { authenticate(allow_sub: true) }

  def index
    @folders = edesk_service(upvs_identity).folders
  end
end
