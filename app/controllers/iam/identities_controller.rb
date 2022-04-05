class Iam::IdentitiesController < ApiController
  include Pagination

  before_action { authenticate(allow_sub: true) }

  before_action(only: :search) { set_page }
  before_action(only: :search) { set_per_page(default: 10, range: 10..100) }

  before_action(only: :search) { render_bad_request(:missing, :query) if request.request_parameters.blank? }

  rescue_from(sk.gov.schemas.identity.service._1_7.GetIdentityFault) { |error| render_bad_request(:invalid, :identity_id, upvs_fault(error)) }
  rescue_from(sk.gov.schemas.identity.service._1_7.GetEdeskInfo2Fault) { |error| render_bad_request(:invalid, :query, upvs_fault(error)) }

  def show
    @identity = iam_repository(upvs_identity).identity(params[:id])
  end

  def search
    query = params.permit(
      :match, :page, :per_page,
      :en, :email, :phone,
      ids: [],
      uris: [],
      address: [:type, :country, :district, :municipality, :street, :building_number, :registration_number],
      corporate_body: [:cin, :tin, :name],
      natural_person: [:given_name, :family_name, :date_of_birth, :place_of_birth],
    )

    @identities = iam_repository(upvs_identity).search(query.to_options.merge(page: page, per_page: per_page))
  end
end
