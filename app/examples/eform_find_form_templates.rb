require_relative '../../config/environment'

eform = UpvsEnvironment.upvs_proxy(nil).eform
eform.call_service(sk.gov.schemas.servicebus.service._1.ServiceClassEnum::EFORM_FINDFORMTEMPLATES_SOAP_V_1_0, nil)