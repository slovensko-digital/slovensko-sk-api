# TODO use #alias_matcher instead of #alias once RubyMine starts to recognize aliases on click-to-reference

module UpvsObjectMatchers
  extend RSpec::Matchers::DSL

  matcher :be_upvs_object do |expected|
    match do |actual|
      expected_as_struct = UpvsObjects.to_structure(expected)
      actual_as_struct = UpvsObjects.to_structure(actual)

      warn 'WARNING: Comparing two blank UPVS objects is unsafe' if expected_as_struct.blank? && actual_as_struct.blank?

      result = expected.instance_of?(actual.class) && values_match?(expected_as_struct, actual_as_struct)

      unless result
        @expected_formatted = RSpec::Support::ObjectFormatter.format(expected)
        @actual_formatted = RSpec::Support::ObjectFormatter.format(actual)

        @expected_as_array = [expected_as_struct]
        @actual = actual_as_struct
      end

      result
    end

    def failure_message
      "\nexpected: #{@expected_formatted}\n     got: #{@actual_formatted}\n\n(#{failure_message_note})\n"
    end

    def failure_message_when_negated
      "\nexpected: value != #{@expected_formatted}\n     got: #{@actual_formatted}\n\n(#{failure_message_note})\n"
    end

    def failure_message_note
      'compared using Upvs#to_struct(expected) == Upvs#to_struct(actual)'
    end

    diffable
  end

  def usr_service_call_args(file)
    object = upvs_object_from_xml(file)
    [object.service_class, be_upvs_object(object.service_parameter.value)]
  end

  alias usr_args usr_service_call_args

  def be_usr_service_result(file)
    be_upvs_object(usr_service_result(file))
  end
end

RSpec.configure do |config|
  config.include UpvsObjectMatchers
end
