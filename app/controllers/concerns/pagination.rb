module Pagination
  extend ActiveSupport::Concern

  included do
    attr_accessor :page, :per_page

    private

    # TODO consider translating parameters and resources: t(:page) -> 'Page number'

    def set_page(default: 1, maximum: nil)
      self.page = Integers.parse_positive(params.fetch(:page, default))
      render_bad_request(:out_of_range, :page_number) if maximum && page > maximum
    rescue ArgumentError
      render_bad_request(:invalid, :page_number)
    end

    def set_per_page(default: 50, range: 10..100)
      self.per_page = Integers.parse_positive(params.fetch(:per_page, default))
      render_bad_request(:out_of_range, :per_page_number) unless per_page.in?(range)
    rescue ArgumentError
      render_bad_request(:invalid, :per_page_number)
    end
  end
end
