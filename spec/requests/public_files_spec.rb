require 'rails_helper'

RSpec.describe 'Public files' do
  it 'serves installation guide as plain text in utf-8' do
    get '/install.md'

    expect(response.status).to eq(200)
    expect(response.headers['content-type']).to eq('text/plain; charset=utf-8')
  end

  it 'serves documentation as plain text in utf-8' do
    get '/openapi.yaml'

    expect(response.status).to eq(200)
    expect(response.headers['content-type']).to eq('text/plain; charset=utf-8')
  end
end
