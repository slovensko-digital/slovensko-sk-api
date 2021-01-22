# TODO validate form version status
# TODO validate resulting builder message against XSD
# TODO test response against openapi.yml see https://github.com/apiaryio/dredd

module SktalkReceiving
  extend ActiveSupport::Concern

  included do
    private

    def receive_sktalk_message(builder, with_objects:, &form)
      message = builder.new(**params.permit(:message_id, :correlation_id).to_options) { |m|
        m.message_container(**params.permit(:sender_uri, :recipient_uri).to_options) {
          m.form_object(&form)
          params.require(:objects).each { |object|
            m.object(**object.permit(:id, :name, :description, :class, :signed, :mime_type, :encoding).to_options) {
              m << object.require(:content)
            }
          } if with_objects
        }
      }

      # TODO get save_to_outbox from params
      render_sktalk_results sktalk_receiver(upvs_identity).receive!(message.to_xml, save_to_outbox: false)
    end

    def render_sktalk_results(results)
      render status: (results.receive_timeout || results.save_to_outbox_timeout) ? :request_timeout : :ok, json: results
    end
  end
end
