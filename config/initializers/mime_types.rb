# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
Mime::Type.register 'application/health+json', :health
Mime::Type.register 'application/samlassertion+xml', :saml

# Serve public documentation as UTF-8 plain text, static file server derives content type from these.
Rack::Mime::MIME_TYPES.merge!('.md' => 'text/plain; charset=utf-8', '.yaml' => 'text/plain; charset=utf-8')
