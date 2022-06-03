Rails.application.routes.draw do
  scope format: false do
    namespace :administration do
      resources :certificates, only: [:create, :show, :destroy]

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

    if UpvsEnvironment.obo_support?
      post :login, to: 'upvs#login_with_saml_assertion'
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
        get :prepare_for_later_receive
      end

      if UpvsEnvironment.obo_support?
        namespace :upvs do
          get :assertion
          get :identity
        end
      end
    end

    match '500', to: 'errors#internal_server_error', via: :all
  end
end
