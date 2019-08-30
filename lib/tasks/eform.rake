namespace :eform do
  task sync: :environment do
    DownloadFormTemplatesJob.perform_later
  end
end
