require_relative 'application'

Rails.application.load_tasks

module Clockwork
  configure do |config|
    config[:thread] = true
    config[:tz] = Rails.application.config.time_zone
  end

  handler do |name|
    Rake::Task[name].reenable
    Rake::Task[name].invoke
  end

  every(1.day, 'eform:sync', at: '5:00') if ENV['EFORM_SYNC'] != 'false'
end
