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
