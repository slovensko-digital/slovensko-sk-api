source 'https://rubygems.org'

ruby '2.5.0', engine: 'jruby', engine_version: '9.2.0.0'

gem 'rails', '~> 5.2.1'
gem 'activerecord-jdbcpostgresql-adapter'
gem 'puma', '~> 3.11'
gem 'omniauth-saml'
gem 'jwt'
gem 'delayed_job_active_record'
gem 'clockwork'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

group :development, :test do
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'pry'
end

group :development do
  gem 'annotate'
  gem 'listen'
end
