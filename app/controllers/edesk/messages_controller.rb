class Edesk::MessagesController < ApiController
  around_action :raise_on_unpermitted_parameters, only: :search

  include EdeskRescuable
  include Pagination

  mattr_reader :edesk_message_parser, default: EdeskMessageParser.new

  before_action { authenticate(allow_sub: true) }

  before_action(only: [:index, :search]) { set_page }
  before_action(only: [:index, :search]) { set_per_page(default: 50, range: 10..5000) }

  before_action(only: :index) { render_bad_request(:invalid, :folder_id) unless match_positive?(params[:folder_id]) }
  before_action(only: :update) { render_bad_request(:invalid, :folder_id) if params.require(:folder_id).to_i <= 0 }
  before_action(only: :search) { render_bad_request(:invalid, :correlation_id) unless UUID_PATTERN.match?(params.require(:correlation_id)) }
  before_action(except: [:index, :search]) { render_bad_request(:invalid, :message_id) unless match_positive?(params[:id]) }

  def index
    @messages = edesk_service(upvs_identity).messages(params[:folder_id].to_i, page: page, per_page: per_page)
  end

  def show
    @message = edesk_message_parser.parse(edesk_service(upvs_identity).message(params[:id].to_i))
  end

  def search
    @messages = edesk_service(upvs_identity).filter_messages(search_params, page: page, per_page: per_page)
  end

  def update
    edesk_service(upvs_identity).move_message(params[:id].to_i, params[:folder_id].to_i)

    head :no_content
  end

  def destroy
    edesk_service(upvs_identity).delete_message(params[:id].to_i)

    head :no_content
  end

  def authorize
    render json: { authorized_message_id: edesk_service(upvs_identity).authorize_message(params[:id].to_i) }
  end

  private

  UUID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

  def require_request_body?
    super && action_name != 'authorize'
  end

  def search_params
    params.permit(:format, :token, :page, :per_page, :correlation_id).except(:format, :token, :page, :per_page)
  end

  def raise_on_unpermitted_parameters
    begin
      ActionController::Parameters.action_on_unpermitted_parameters = :raise
      yield
    ensure
      ActionController::Parameters.action_on_unpermitted_parameters = :log
    end
  end

  delegate :match_positive?, to: Integers
end
