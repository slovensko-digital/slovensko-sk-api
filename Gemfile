source 'https://rubygems.org'

ruby '2.5.7', engine: 'jruby', engine_version: '9.2.14.0'

gem 'rails', '~> 5.2.4.4'
gem 'tzinfo-data', platforms: [:jruby]
gem 'puma'

# Drivers
gem 'activerecord-jdbcpostgresql-adapter'
gem 'redis'

# Security
gem 'omniauth-saml'
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

gem 'rake', '13.0.1' # TODO resolve problem with deployments

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
