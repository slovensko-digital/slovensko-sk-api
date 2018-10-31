# TODO remove this: force timeout via http://cxf.apache.org/docs/client-http-transport-including-ssl-support.html#ClientHTTPTransport(includingSSLsupport)-Theclientelement

module ForceTimeout
  extend ActiveSupport::Concern

  WAIT = 60.seconds

  included do
    include ActiveSupport::Rescuable

    private

    def timeout(wait = WAIT, &block)
      SafeTimeout.timeout(wait, SafeTimeoutError, &block)
    rescue => error
      rescue_with_handler(error) || raise
    end
  end
end
