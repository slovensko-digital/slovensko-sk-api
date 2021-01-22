require_relative 'boot'

require 'rails'

# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
# require 'active_storage/engine'
require 'action_controller/railtie'
# require 'action_mailer/railtie'
require 'action_view/railtie'
# require 'action_cable/engine'
# require 'sprockets/railtie'
# require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module SlovenskoSkApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Add cookies back
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore

    # Set local time zone
    config.active_record.default_timezone = :utc
    config.time_zone = ENV['TIME_ZONE'] || 'Europe/Bratislava'

    # Set default locale
    config.i18n.default_locale = :en

    # Set job worker
    config.active_job.queue_adapter = :delayed_job

    # Set error handler
    config.exceptions_app = self.routes

    # Set static files server
    config.public_file_server.headers = {}
    config.public_file_server.headers['Access-Control-Allow-Origin'] = '*'
    config.public_file_server.headers['Content-Type'] = 'text/plain; charset=utf-8'
  end
end

# Require Java
require 'java'

Kernel.define_method(:digital) { Java::Digital }
Kernel.define_method(:sk) { Java::Sk }

# Require libraries
require 'keystore'
require 'open3'
require 'parameters'
require 'upvs'
