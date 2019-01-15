namespace :eform do
  task sync: :environment do
    DownloadAllFormTemplatesJob.perform_later
  end
end
