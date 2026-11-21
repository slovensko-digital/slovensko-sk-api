# Be sure to restart your server when you modify this file.

# Disable parameter wrapping for JSON, requests are processed as sent.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: []
end
