Rails.application.routes.draw do
  get :health, to: 'health#index'

  scope as: :upvs, path: 'auth/saml', controller: :upvs do
    get :login
    get :logout

    post :callback
  end

  namespace :sktalk do
    post :receive
  end
end
