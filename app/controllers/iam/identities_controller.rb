class Iam::IdentitiesController < ApiController
  include Pagination

  before_action { authenticate(allow_sub: true) }

  before_action(only: :search) { set_page }
  before_action(only: :search) { set_per_page(default: 10, range: 10..100) }

  before_action(only: :search) { render_bad_request(:missing, :query) if request.request_parameters.blank? }

  rescue_from(sk.gov.schemas.identity.service._1_7.GetIdentityFault, with: :render_identity_fault)
  rescue_from(sk.gov.schemas.identity.service._1_7.GetEdeskInfo2Fault) { |error| render_bad_request(:invalid, :query, upvs_fault(error)) }

  CODE_LIST_ATTRIBUTES = [:id, :name]

  def show
    @identity = iam_repository(upvs_identity).identity(params[:id])
  end

  def lookup
    permitted_params = params.permit(
      :personal_identification_number,
      :given_name,
      :family_name,
      :company_registration_number
    ).to_options

    lookup_params = IdentityLookupParams.new(permitted_params)
    return render_bad_request(:invalid, :query) if lookup_params.invalid?

    @identity = iam_repository(upvs_identity).identity(
      nil,
      personal_identification_number: lookup_params.personal_identification_number,
      given_name: lookup_params.given_name,
      family_name: lookup_params.family_name,
      company_registration_number: lookup_params.company_registration_number
    )
  end

  def search
    query = params.permit(
      :match, :page, :per_page,
      :en, :email, :phone,
      ids: [],
      uris: [],
      address: [:type, :street, :building_number, :registration_number, :municipality => CODE_LIST_ATTRIBUTES, :country => CODE_LIST_ATTRIBUTES, :district => CODE_LIST_ATTRIBUTES],
      corporate_body: [:cin, :tin, :name],
      natural_person: [:given_name, :family_name, :date_of_birth, :place_of_birth],
    )

    @identities = iam_repository(upvs_identity).search(query.to_options.merge(page: page, per_page: per_page))
  end

  private

  def render_identity_fault(error)
    param = action_name == 'show' ? :identity_id : :query
    render_bad_request(:invalid, param, upvs_fault(error))
  end
end
