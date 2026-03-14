Sinaliza::Engine.routes.draw do
  resources :events, only: [ :index, :show ]
  resources :interceptors, except: [ :show ] do
    member do
      patch :toggle
    end
  end
  root to: "events#index"
end
