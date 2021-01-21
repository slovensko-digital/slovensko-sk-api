module UpvsObjects
  extend self

  mattr_reader :datatype_factory, default: javax.xml.datatype.DatatypeFactory.new_instance

  delegate :from_xml, :to_xml, to: digital.slovensko.upvs.UpvsObjects

  def to_structure(object)
    to_ruby_object(digital.slovensko.upvs.UpvsObjects.to_structure(object))
  end

  alias_method :to_struct, :to_structure

  private

  def to_ruby_object(object)
    return object.to_a.map { |e| to_ruby_object(e) } if object.is_a?(java.util.Collection)
    return object.to_h.map { |k, v| [to_ruby_key(k), to_ruby_object(v)] }.to_h if object.is_a?(java.util.Map)
    object
  end

  def to_ruby_key(key)
    key.is_a?(String) ? key.underscore : to_ruby_object(key)
  end
end
