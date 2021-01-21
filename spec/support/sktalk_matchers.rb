# TODO wrap matchers in module?
# TODO add proper #failure_message for all matchers
# TODO consider chained setters https://relishapp.com/rspec/rspec-expectations/v/3-9/docs/custom-matchers/define-matcher-with-fluent-interface#chained-setter

RSpec::Matchers.define :sktalk_message do
  match do |message|
    message.is_a?(sk.gov.sktalkmessage.SKTalkMessage) &&
    (@class ? message.header.message_info.clazz == @class : true)
  end

  chain :saving_to_outbox do
    @class = 'EDESK_SAVE_APPLICATION_TO_OUTBOX'
  end

  chain :with_class, :class

  # TODO add chains here and remove all matchers below
end

RSpec::Matchers.define :sktalk_message_of_class do |clazz|
  match { |message| message.header.message_info.clazz = clazz.to_s }
end

RSpec::Matchers.define :sktalk_message_in_correlation_with do |id|
  match { |message| message.header.message_info.correlation_id = id.to_s }
end

RSpec::Matchers.define :sktalk_message_referencing do |id|
  match { |message| message.header.message_info.reference_id = id.to_s }
end

RSpec::Matchers.define :sktalk_message_containing do |value, at:, **options|
  match { |message| Nokogiri::XML::Document.wrap(message.body.any.first.owner_document).at_xpath(at, options).content == value }
end

RSpec::Matchers.define :sktalk_message_matching do |content|
  match do |expected|
    actual = SktalkMessages.from_xml(content)
    actual.header.message_info.clazz = @class if @class

    SktalkMessages.to_xml(expected) == SktalkMessages.to_xml(actual)
  end

  chain :saving_to_outbox do
    @class = 'EDESK_SAVE_APPLICATION_TO_OUTBOX'
  end
end
