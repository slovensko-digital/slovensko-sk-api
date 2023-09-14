module EdeskRescuable
  extend ActiveSupport::Concern

  included do
    faults = [
      sk.gov.schemas.edesk.eksservice._1.IEKSServiceGetFoldersEDeskFaultFaultFaultMessage,
      sk.gov.schemas.edesk.eksservice._1.IEKSServiceGetMessagesEDeskFaultFaultFaultMessage,
      sk.gov.schemas.edesk.eksservice._1.IEKSServiceGetMessageEDeskFaultFaultFaultMessage,
      sk.gov.schemas.edesk.eksservice._1.IEKSServiceDeleteMessageEDeskFaultFaultFaultMessage,
      sk.gov.schemas.edesk.eksservice._1.IEKSServiceMoveMessageEDeskFaultFaultFaultMessage,
      sk.gov.schemas.edesk.eksservice._1.IEKSServiceConfirmNotificationReportEDeskFaultFaultFaultMessage
    ]

    rescue_from *faults do |error|
      logger.debug { error.full_message }

      java_import org.datacontract.schemas._2004._07.anasoft_edesk.FaultCodes

      case error.fault_info.code
      when FaultCodes::E_DESK_INACTIVE then render_conflict(:inactive_box)
      when FaultCodes::E_DESK_PERMISSION_DENIED
        case error.message
        when /schránk[ay]/i then render_not_found(:box)
        when /priečinok/i then render_not_found(:folder)
        when /správ[au]/i then render_not_found(:message)
        else
          internal_server_error
        end
      when FaultCodes::E_DESK_NOT_EXIST then render_not_found(:box)
      when FaultCodes::FOLDER_NOT_EXIST then render_not_found(:folder)
      when FaultCodes::MESSAGE_NOT_EXIST then render_not_found(:message)
      when FaultCodes::MESSAGE_NOT_DELIVERABLE then render_unprocessable_entity(:notification_report_already_confirmed)
      when FaultCodes::INCORRECT_CONFIRM_REQUEST
        case error.message
        when /Správa \d+ nemá Class ED_DELIVERY_NOTIFICATION, a teda nie je notifikačná doručenka./ then render_unprocessable_entity(:authorize_non_notification_report)
        when /Správa \d+ neexistuje./ then render_not_found(:message)
        when 'Nie ste adresátom správy a preto ju nemáte oprávnenie prevziať.' then render_not_found(:message)
        else
          internal_server_error
        end
      else
        render_service_unavailable_error(:ekr)
      end
    end
  end
end
