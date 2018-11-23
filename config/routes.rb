Rails.application.routes.draw do
  get :health, to: 'health#index'

  get :login, to: 'upvs#login'
  get :logout, to: 'upvs#logout'

  scope as: :upvs, path: 'auth/saml', controller: :upvs do
    get :login
    get :logout

    post :callback
  end

  scope :api do

    # TODO rm
    namespace :poc do
      get :try
    end

    namespace :sktalk do
      post :receive
      post :receive_and_save_to_outbox
    end
  end
end
