# TODO consider to remove this helpers if it remains unused

module UpvsObjects
  extend self

  def to_structure(object)
    to_ruby_object(digital.slovensko.upvs.UpvsObjects.to_structure(object))
  end

  private

  def to_ruby_object(object)
    return object.to_a.map { |e| to_ruby_object(e) } if object.is_a?(java.util.Collection)
    return object.to_h.map { |k, v| [to_ruby_key(k), to_ruby_object(v)]}.to_h if object.is_a?(java.util.Map)
    object
  end

  def to_ruby_key(key)
    return to_ruby_object(key) unless key.is_a?(String)
    fix = { 'clazz' => 'class', 'e_desk' => 'edesk', 'sk_talk' => 'sktalk' }
    fix.inject(key.underscore) { |k, (p, r)| k.sub(/(\A|_)#{p}(_|\z)/i, r) }
  end
end
