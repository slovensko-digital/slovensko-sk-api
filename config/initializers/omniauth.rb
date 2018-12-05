# Be sure to restart your server when you modify this file.

# Enable test mode in test environment.
OmniAuth.config.test_mode = true if Rails.env.test?

# Raise errors in every environment instead of redirecting to the default error page.
OmniAuth.config.failure_raise_out_environments = ['development', 'production', 'staging', 'test']
