module CallbackHelper
  def callback_match?(template, callback = params[:callback])
    uri_scheme_and_authority(callback) == uri_scheme_and_authority(template) && callback.start_with?(template)
  end

  private

  def uri_scheme_and_authority(uri)
    URI(uri).tap { |u| u.path = u.query = u.fragment = nil }
  end
end
