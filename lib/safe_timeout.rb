module SafeTimeout
  extend self

  def timeout(seconds, error_class = nil)
    raise java.lang.NullPointerException.new unless block_given?

    callable = Class.new {
      include java.util.concurrent.Callable
      define_method(:call) { yield }
    }.new

    timeout_duration = (seconds * 1_000_0000_000).to_i
    timeout_unit = java.util.concurrent.TimeUnit::NANOSECONDS

    time_limiter.call_with_timeout(callable, timeout_duration, timeout_unit)
  rescue java.util.concurrent.TimeoutException => error
    raise error_class ? error_class : error
  end

  private

  def time_limiter
    @time_limiter ||= com.google.common.util.concurrent.SimpleTimeLimiter::create(ESH.executor_service)
  end

  # Shared executor service across all extensions, it waits 120 seconds before JVM termination

  module ESH
    def self.executor_service
      @executor_service ||= exiting_service(java.util.concurrent.Executors::new_cached_thread_pool)
    end

    def self.exiting_service(executor_service)
      com.google.common.util.concurrent.MoreExecutors::get_exiting_executor_service(executor_service)
    end
  end

  private_constant :ESH
end

SafeTimeoutError = java.util.concurrent.TimeoutException
