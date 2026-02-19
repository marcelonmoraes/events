Rails.application.routes.draw do
  mount Events::Engine => "/events"

  resources :tracked, only: [ :index, :show, :create ]
end
