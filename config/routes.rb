Rails.application.routes.draw do
  resource :session
  resource :setup, only: %i[ new create ]

  resources :job_applications, path: "candidaturas", except: :show do
    collection do
      post :import
      post :check_replies
    end
    member { patch :move }
  end
  resources :contacts, path: "contatos", except: :show
  resources :job_postings, path: "vagas", only: %i[ index show new create ] do
    collection do
      post :fetch
      post :dismiss_all
    end
    member do
      post :save
      post :apply
      post :dismiss
      post :restore
    end
    resources :ai_artifacts, path: "ia", only: :create do
      collection { get :estimate, path: "estimativa" }
    end
  end
  resources :ai_artifacts, path: "ia", only: %i[ show destroy ]
  resource :settings, path: "ajustes", only: %i[ show update ] do
    post :backup
  end
  resources :push_subscriptions, only: %i[ create destroy ] do
    collection do
      delete :unsubscribe
      post :test
    end
  end
  resources :target_companies, path: "empresas-alvo", except: :show do
    collection { post :find }
    member do
      post :activate
      post :dismiss
    end
  end

  resource :radar, only: :show, controller: "radar"
  resources :consultancies, only: :update
  resources :message_templates, path: "mensagens", except: :show
  resource :routine, only: :show, path: "rotina" do
    post "itens/:key", action: :toggle, as: :toggle
  end

  namespace :api do
    namespace :v1 do
      resources :job_postings, only: :create
      get "ping", to: "pings#show"
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#show"
end
