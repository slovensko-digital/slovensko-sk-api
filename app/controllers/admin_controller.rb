class AdminController < ApiController
  before_action { authenticate }

  def eform_sync
    DownloadFormTemplatesJob.perform_later

    render json: { message: 'eForm synchronization scheduled to be performed later' }
  end
end
