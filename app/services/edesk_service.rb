class EdeskService
  def initialize(proxy)
    @upvs = proxy
  end

  def folders
    @upvs.eks.get_folders.values.value.folder.to_a
  end

  def messages(folder_id, page: 1, per_page: 50)
    @upvs.eks.get_messages(folder_id, per_page, (page - 1) * per_page).values.value.message.to_a
  end

  def filter_messages(filter_params, page: 1, per_page: 50)
    filter = build_message_filter(filter_params)
    @upvs.eks.get_messages_by_filter(filter, per_page, (page - 1) * per_page).values.value.message.to_a
  end

  def message(message_id)
    # fix non-existing message as UPVS returns nothing in this case
    @upvs.eks.get_message(message_id) || raise(build_fault(GET_FAULT))
  end

  def authorize_message(message_id)
    @upvs.eks.confirm_notification_report(message_id)
  end

  def delete_message(message_id, force: true)
    # fix non-existing message as UPVS returns nothing in case of deletion
    self.message(message_id) unless force
    @upvs.eks.delete_message(message_id)
  rescue GET_FAULT
    raise build_fault(DELETE_FAULT)
  end

  def move_message(message_id, folder_id)
    @upvs.eks.move_message(message_id, folder_id)
  end

  private

  GET_FAULT = sk.gov.schemas.edesk.eksservice._1.IEKSServiceGetMessageEDeskFaultFaultFaultMessage
  DELETE_FAULT = sk.gov.schemas.edesk.eksservice._1.IEKSServiceDeleteMessageEDeskFaultFaultFaultMessage

  mattr_reader :factory, default: org.datacontract.schemas._2004._07.anasoft_edesk_edeskii.ObjectFactory.new

  def build_filter_item(name, value)
    filter_item = org.datacontract.schemas._2004._07.anasoft_edesk_edeskii.FilterItem.new
    filter_item.set_name(factory.create_filter_item_name(name))
    filter_item.set_value(factory.create_filter_item_value(value))

    filter_item
  end

  def build_array_of_filter_items(filter_params)
    array_of_filter_items = org.datacontract.schemas._2004._07.anasoft_edesk_edeskii.ArrayOfFilterItem.new

    filter_params.each do |key, value|
      case key.to_s
      when 'correlation_id'
        filter_item = build_filter_item('CorrelationId', value)
        array_of_filter_items.get_filter_item().add(filter_item)
      end
    end

    array_of_filter_items
  end

  def build_message_filter(filter_params)
    array_of_filter_items = build_array_of_filter_items(filter_params)

    filter = org.datacontract.schemas._2004._07.anasoft_edesk_edeskii.Filter.new
    filter.set_items(factory.create_filter_items(array_of_filter_items))

    filter
  end

  def build_fault(type)
    factory = org.datacontract.schemas._2004._07.anasoft_edesk.ObjectFactory.new

    fault = factory.create_edesk_fault
    fault.code = org.datacontract.schemas._2004._07.anasoft_edesk.FaultCodes::MESSAGE_NOT_EXIST
    fault.reason = factory.create_edesk_fault_reason('Správa neexistuje.')

    type.new(fault.reason.value, fault)
  end

  private_constant :GET_FAULT, :DELETE_FAULT
end
