RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers

  config.after(:example) { travel_back }
end
