class ActionController::Parameters
  def to_options
    to_h.deep_symbolize_keys
  end
end
