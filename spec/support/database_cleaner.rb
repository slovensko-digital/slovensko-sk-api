require 'database_cleaner/active_record'
require 'database_cleaner/redis'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:example) do |example|
    DatabaseCleaner.cleaning { example.run }
  end
end
