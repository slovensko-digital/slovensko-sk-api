RSpec::Matchers.define :sktalk_message_of_class do |clazz|
  match { |message| message.header.message_info.clazz = clazz }
end
