Rails.application.routes.draw do
  scope format: false do
    namespace :administration do
      namespace :eform do
        get :synchronize
      end
    end

    get :health, to: 'health#index'

    if UpvsEnvironment.sso_support?
      get :login, to: 'upvs#login'
      get :logout, to: 'upvs#logout'

      scope 'auth/saml', as: :upvs, controller: :upvs do
        get :login
        get :logout

        post :callback
      end
    end

    scope :api do
      namespace :eform do
        get :status
        post :validate
      end

      namespace :iam do
        resources :identities, only: [:show] do
          collection do
            post :search
          end
        end
      end

      namespace :sktalk do
        post :receive
        post :receive_and_save_to_outbox
        post :save_to_outbox
      end

      if UpvsEnvironment.sso_support?
        namespace :upvs do
          get :assertion, path: 'sso/assertion'
        end
      end
    end

    match '500', to: 'errors#internal_server_error', via: :all
  end
end
