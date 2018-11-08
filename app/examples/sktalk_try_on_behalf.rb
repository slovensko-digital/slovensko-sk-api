require_relative '../../config/environment'

properties = UpvsEnvironment.upvs_properties(nil)
upvs = digital.slovensko.upvs.UpvsProxy_StsOnBehalf.new(properties)

receiver = SktalkReceiver.new(upvs)
saver = SktalkSaver.new(receiver)

message = File.read('tmp/egov_application_csru_generic.xml')

receive_result = receiver.receive(message)
save_to_outbox_result = saver.save_to_outbox(message)

puts receive_result
puts save_to_outbox_result
