source 'https://rubygems.org'

ruby '2.5.8', engine: 'jruby', engine_version: '9.2.19.0'

gem 'rails', '~> 5.2.6'
gem 'tzinfo-data', platforms: [:jruby]
gem 'puma'

# Drivers
gem 'activerecord-jdbcpostgresql-adapter'
gem 'redis'

# Security
gem 'omniauth-saml', '~> 1.10' # TODO unlock this once https://sluzbyslovenskodigital.atlassian.net/browse/API-103 is resolved
gem 'jwt'

# Workers
gem 'clockwork'
gem 'delayed_job_active_record'

# Utilities
gem 'htmlentities'
gem 'jbuilder'
gem 'nokogiri'
gem 'rubyzip'
gem 'xmldsig'

gem 'i18n', '1.8.7' # TODO unlock this once https://github.com/jruby/jruby/issues/6547 and https://github.com/ruby-i18n/i18n/issues/555 are resolved

group :development, :test do
  gem 'database_cleaner-active_record'
  gem 'database_cleaner-redis'
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'mock_redis'
  gem 'pry-rails'
  gem 'rspec-rails'
  gem 'super_diff'
end

group :development do
  gem 'annotate'
  gem 'listen'
end
