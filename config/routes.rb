Rails.application.routes.draw do
  resource :session
  resource :setup, only: %i[ new create ]

  resources :job_applications, path: "candidaturas", except: :show do
    collection { post :import }
    member { patch :move }
  end
  resources :contacts, path: "contatos", except: :show
  resources :job_postings, path: "vagas", only: %i[ index show new create ] do
    collection { post :fetch }
    member do
      post :save
      post :dismiss
      post :restore
    end
  end
  resources :target_companies, path: "empresas-alvo", except: :show

  resource :radar, only: :show, controller: "radar"
  resources :consultancies, only: :update
  resources :message_templates, path: "mensagens", except: :show
  resource :routine, only: :show, path: "rotina" do
    post "itens/:key", action: :toggle, as: :toggle
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#show"
end
