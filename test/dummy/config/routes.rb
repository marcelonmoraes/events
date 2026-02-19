Rails.application.routes.draw do
  mount Events::Engine => "/events"
end
