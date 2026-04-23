class IdentityLookupParams
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :personal_identification_number, :string
  attribute :given_name, :string
  attribute :family_name, :string
  attribute :company_registration_number, :string

  validate :validate_search_criteria

  private

  def validate_search_criteria
    has_company_registration_number = company_registration_number.present?
    has_personal_info = personal_identification_number.present? &&
                        given_name.present? &&
                        family_name.present?

    return if has_company_registration_number || has_personal_info

    errors.add(:base, 'Either company_registration_number, or all three of personal_identification_number, given_name, and family_name must be provided')
  end
end
