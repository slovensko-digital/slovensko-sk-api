# TODO move to upvs_proxy_errors.rb

module JavaExceptions
  def bean_creation_exception_with_cause(type, message = nil)
    org.springframework.beans.factory.BeanCreationException.new(nil, initialize_or_reuse_cause(type, message))
  end

  def soap_fault_exception(message = 'Unknown reason')
    fault = javax.xml.soap.SOAPFactory.new_instance.create_fault(message, javax.xml.namespace.QName.new('http://www.w3.org/2003/05/soap-envelope', 'Sender'))
    javax.xml.ws.soap.SOAPFaultException.new(fault)
  end

  def soap_fault_exception_with_cause(type, message = nil)
    soap_fault_exception.tap { |exception| exception.init_cause(initialize_or_reuse_cause(type, message)) }
  end

  def soap_certificate_exception
    message = '00900003 : PoÅ¾iadavka je podpÃ­sanÃ¡ s nevalidnÃ½m AC. Kontaktujte administrÃ¡tora s nasledujÃºcim kÃ³dom : Id-546e735e14039cdef0f8f1c8'
    javax.xml.ws.WebServiceException.new(org.apache.cxf.binding.soap.SoapFault.new(message, nil))
  end

  def soap_timeout_exception
    soap_fault_exception('Problem writing SAAJ model to stream: connect timed out')
  end

  def runtime_exception_as_rescuable(type, message)
    java.lang.RuntimeException.new(message).tap do |error|
      allow(type).to receive(:===).and_call_original
      allow(type).to receive(:===).with(error).and_return(true)
    end
  end

  def raise_bean_creation_exception_with_cause(type, message)
    raise_error(org.springframework.beans.factory.BeanCreationException) do |error|
      cause = error.most_specific_cause
      expect(cause).to be_kind_of(type)
      expect(cause.message).to error_message_to_matcher(message)
    end
  end

  def raise_soap_fault_exception(message)
    raise_error(javax.xml.ws.soap.SOAPFaultException) do |error|
      expect(error.message).to error_message_to_matcher(message)
      expect(error.fault.fault_code).to eq('env:Sender')
      expect(error.fault.fault_string).to error_message_to_matcher(message)
      expect(error.fault.fault_reason_texts.first).to error_message_to_matcher(message)
    end
  end

  def raise_soap_fault_exception_with_cause(type, message)
    raise_error(javax.xml.ws.soap.SOAPFaultException) do |error|
      cause = error.cause
      cause = cause.most_specific_cause if cause.is_a?(org.springframework.beans.factory.BeanCreationException)
      expect(cause).to be_kind_of(type)
      expect(cause.message).to error_message_to_matcher(message)
    end
  end

  def raise_web_service_exception_with_cause(type, message)
    raise_error(javax.xml.ws.WebServiceException) do |error|
      cause = error.cause
      expect(cause).to be_kind_of(type)
      expect(cause.message).to error_message_to_matcher(message)
    end
  end

  private

  def initialize_or_reuse_cause(type, message = nil)
    message ? type.new(message) : type
  end

  def error_message_to_matcher(message)
    message.respond_to?(:matches?) ? message : eq(message)
  end
end

RSpec.configure do |config|
  config.include JavaExceptions
end
