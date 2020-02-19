class ActionDispatch::TestResponse
  def object
    JSON.parse(body, symbolize_names: true)
  end
end
