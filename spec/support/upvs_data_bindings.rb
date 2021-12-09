# TODO rename eks_ to ekr_
# TODO rename ez_ to usr_
# TODO use #alias_method instead of #alias once RubyMine starts to recognize aliases on click-to-reference

module UpvsDataBindings
  def upvs_object_from_xml(file)
    UpvsObjects.from_xml(file_fixture(file).read)
  end

  alias ekr_response upvs_object_from_xml

  def eks_get_folders_fault(file)
    ekr_error_from_xml(file, sk.gov.schemas.edesk.eksservice._1.IEKSServiceGetFoldersEDeskFaultFaultFaultMessage)
  end

  def eks_get_messages_fault(file)
    ekr_error_from_xml(file, sk.gov.schemas.edesk.eksservice._1.IEKSServiceGetMessagesEDeskFaultFaultFaultMessage)
  end

  def eks_get_message_fault(file)
    ekr_error_from_xml(file, sk.gov.schemas.edesk.eksservice._1.IEKSServiceGetMessageEDeskFaultFaultFaultMessage)
  end

  def eks_move_message_fault(file)
    ekr_error_from_xml(file, sk.gov.schemas.edesk.eksservice._1.IEKSServiceMoveMessageEDeskFaultFaultFaultMessage)
  end

  def eks_delete_message_fault(file)
    ekr_error_from_xml(file, sk.gov.schemas.edesk.eksservice._1.IEKSServiceDeleteMessageEDeskFaultFaultFaultMessage)
  end

  def eks_authorize_message_fault(file)
    ekr_error_from_xml(file, sk.gov.schemas.edesk.eksservice._1.IEKSServiceConfirmNotificationReportEDeskFaultFaultFaultMessage)
  end

  alias iam_request upvs_object_from_xml
  alias iam_response upvs_object_from_xml

  def iam_get_edesk_info_fault(file)
    iam_error_from_xml(file, sk.gov.schemas.identity.service._1_7.GetEdeskInfo2Fault)
  end

  def iam_get_identity_fault(file)
    iam_error_from_xml(file, sk.gov.schemas.identity.service._1_7.GetIdentityFault)
  end

  def usr_service_class(file)
    upvs_object_from_xml(file).service_class.value
  end

  def usr_service_parameter(file)
    upvs_object_from_xml(file).service_parameter.value
  end

  def usr_service_parameter_as_xml(file)
    data = file_fixture(file).read.match(USR_CALL_SERVICE_REGEXP)
    "#{data[:prolog]}\n<#{data[:root]}#{data[:namespaces]}#{data[:body] ? ">#{data[:body]}</#{data[:root]}>" : '/>'}\n"
  end

  def usr_service_result(file)
    upvs_object_from_xml(file).call_service_result.value
  end

  private

  USR_CALL_SERVICE_REGEXP = /(?<prolog><\?xml.+\?>).+<CallService(?<namespaces>.+)>.+<serviceClass>(?<class>.+)<\/serviceClass>.+<serviceParameter.+xsi:type="(?<root>.+)"(\/>|>(?<body>.+)<\/serviceParameter>)/m

  def ekr_error_from_xml(file, error_class)
    fault = upvs_object_from_xml(file)
    error_class.new(fault.reason.value, fault)
  end

  def iam_error_from_xml(file, error_class)
    fault = upvs_object_from_xml(file)
    error_class.new(fault.fault_message.first, fault)
  end

  private_constant *constants(false)
end

RSpec.configure do |config|
  config.include UpvsDataBindings
end
