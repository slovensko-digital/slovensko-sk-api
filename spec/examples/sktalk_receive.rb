require_relative '../../config/environment'

receiver = UpvsEnvironment.sktalk_receiver(nil)

message = File.read('tmp/egov_application_csru_generic.xml')
result = receiver.receive(message)

puts result
