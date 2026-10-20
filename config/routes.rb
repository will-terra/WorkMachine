Rails.application.routes.draw do
  resource :session
  resource :setup, only: %i[ new create ]

  resources :job_applications, path: "candidaturas", except: :show do
    collection { post :import }
    member { patch :move }
  end
  resources :contacts, path: "contatos", except: :show

  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#show"
end
