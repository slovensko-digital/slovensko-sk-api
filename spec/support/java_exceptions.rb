module JavaExceptions
  def execution_exception(cause)
    java.util.concurrent.ExecutionException.new(cause)
  end

  def soap_fault_exception(message)
    fault = double
    allow(fault).to receive(:getFaultString).and_return(message)
    javax.xml.ws.soap.SOAPFaultException.new(fault)
  end

  def socket_timeout_exception
    java.net.SocketTimeoutException.new
  end
end

RSpec.configure do |config|
  config.include JavaExceptions
end
