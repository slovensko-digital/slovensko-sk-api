module UnwrapErrors
  extend ActiveSupport::Concern

  WRAPPERS = [
    Java::com.google.common.util.concurrent.ExecutionError,
    Java::com.google.common.util.concurrent.UncheckedExecutionException,
    Java::java.util.concurrent.ExecutionException,
    Java::java.lang.reflect.UndeclaredThrowableException,
  ]

  included do
    include ActiveSupport::Rescuable

    # clear last raised error so it does not tamper the cause of unwrapped error

    rescue_from(*WRAPPERS) do |error|
      $! = nil
      raise unwrap_error(error)
    end

    private

    def unwrap_error(error, wrappers = WRAPPERS)
      wrappers.each do |wrapper|
        return unwrap_error(error.cause) if error.is_a?(wrapper)
      end

      error
    end
  end
end
