# Be sure to restart your server when you modify this file.

# This file contains settings for ActionController::ParamsWrapper which is enabled by default.

# Disable parameter wrapping for JSON.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: []
end

# Disable root element in JSON for ActiveRecord objects.
ActiveSupport.on_load(:active_record) do
  self.include_root_in_json = false
end
