class AdminController < ApiController
  before_action { authenticate }

  def eform_sync
    DownloadAllFormTemplatesJob.perform_later

    render status: :ok, json: { message: 'eForm synchronization scheduled to be performed later' }
  end
end
