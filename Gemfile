source 'https://rubygems.org'

ruby '4.0.0', engine: 'jruby', engine_version: '10.1.2.0'

gem 'rails', '~> 8.1.4'
gem 'tzinfo-data', platforms: [:jruby]
gem 'puma'

# Drivers
# TODO switch to activerecord-jdbcpostgresql-adapter once its rails 8.1 release is published,
# until then the base adapter registers postgresql and loads driver from jdbc-postgres on its own
gem 'activerecord-jdbc-adapter', '81.0.pre1'
gem 'jdbc-postgres'
gem 'redis'

# Security
gem 'ruby-saml', '~> 1.18'
gem 'omniauth-saml', '~> 2.2'
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
  gem 'annotaterb'
  gem 'listen'
end
