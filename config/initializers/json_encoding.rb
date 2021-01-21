# Be sure to restart your server when you modify this file.

# Disable HTML entities escaping in encoded values.
ActiveSupport::JSON::Encoding.escape_html_entities_in_json = false

# Use ISO 8601 format for encoded date and time values.
ActiveSupport::JSON::Encoding.use_standard_json_time_format = true

# Use millisecond precision of encoded time values.
ActiveSupport::JSON::Encoding.time_precision = 3
