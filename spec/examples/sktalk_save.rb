require_relative '../../config/environment'

saver = UpvsEnvironment.sktalk_saver(nil)

message = File.read('tmp/egov_application_csru_generic.xml')
result = saver.save_to_outbox(message)

puts result
