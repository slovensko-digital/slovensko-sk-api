namespace :podaas do
  desc 'Download form templates'
  task download_form_templates: :environment do
    DownloadAllFormTemplatesJob.perform_later
  end
end
