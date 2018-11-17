def ensure_upvs_package_existence!
  root = File.expand_path(File.join('lib', 'upvs'), __dir__)
  main = File.join(root, 'bin', 'upvs-0.0.0.jar')

  unless File.exists?(main)
    env = ENV.to_h.merge('JAVA_HOME' => '/app/vendor/jvm')
    result = system(env, File.join(root, 'compile'), out: File::NULL)
    raise 'Error packing UPVS library into JAR file' unless result
  end
end

# TODO use custom Dockerfile instead of this dirty hack
ensure_upvs_package_existence!

source 'https://rubygems.org'

ruby '2.5.0', engine: 'jruby', engine_version: '9.2.0.0'

gem 'rails', '~> 5.2.1'
gem 'activerecord-jdbcpostgresql-adapter'
gem 'puma', '~> 3.11'
gem 'omniauth-saml'

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
