class AdminController < ApplicationController
  def download_all_form_templates
    DownloadAllFormTemplatesJob.perform_later

    render status: :ok, json: { message: 'Scheduled to be performed later' }
  end
end
