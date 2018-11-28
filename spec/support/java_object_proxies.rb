# cache Java object proxy to support user-defined instance variables or singleton
# object on arbitrary Java object, see https://github.com/jruby/jruby/wiki/Persistence

module JavaObjectProxies
  def cache_java_object_proxy!(object)
    object.class.__persistent__ = true
  end
end

RSpec.configure do |config|
  config.include JavaObjectProxies
end
