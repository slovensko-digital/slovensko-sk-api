class Administration::EformController < ApiController
  before_action { authenticate(allow_plain: true) }

  def synchronize
    DownloadFormTemplatesJob.perform_later

    head :no_content
  end
end
