require_relative '../../config/environment'

sktalk_service = UpvsEnvironment.sktalk_service(nil)

message = File.read('tmp/egov_application_csru_generic.xml')
result = sktalk_service.receive(message)

puts result
