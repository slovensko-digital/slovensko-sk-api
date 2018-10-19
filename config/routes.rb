Rails.application.routes.draw do
  get :health, to: 'health#index'

  namespace :sktalk do
    post :receive
  end
end
