Rails.application.routes.draw do
  mount Sinaliza::Engine => "/sinaliza"

  resources :tracked, only: [ :index, :show, :create ]
end
