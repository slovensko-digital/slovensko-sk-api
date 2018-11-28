RSpec::Matchers.define :message_of_class do |clazz|
  match { |message| message.header.message_info.clazz = clazz }
end
