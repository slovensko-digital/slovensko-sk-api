class ActiveSupport::Cache::RedisCacheStore
  def keys
    redis.keys([options[:namespace], '*'].compact * ':')
  end
end

module RedisCacheStores
  def redis_cache_store_without_connection
    error_handler = -> (method:, **) { Environment::REDIS_CONNECTION_ENFORCER.call if method != :clear }
    ActiveSupport::Cache::RedisCacheStore.new(url: 'redis://127.0.0.1:10', error_handler: error_handler)
  end
end

RSpec.configure do |config|
  config.include RedisCacheStores
end

