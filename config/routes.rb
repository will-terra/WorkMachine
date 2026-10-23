Rails.application.routes.draw do
  resource :session
  resource :setup, only: %i[ new create ]

  resources :job_applications, path: "candidaturas", except: :show do
    collection do
      post :import
      post :check_replies
    end
    member { patch :move }
    resources :ai_artifacts, path: "ia", only: :create do
      collection { get :estimate, path: "estimativa" }
    end
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
      post :dream
      post :undo
    end
    resources :ai_artifacts, path: "ia", only: :create do
      collection { get :estimate, path: "estimativa" }
    end
  end
  resources :ai_artifacts, path: "ia", only: %i[ show destroy ]
  namespace :settings, path: "ajustes" do
    resources :routines, path: "rotinas", except: :show do
      post :restore, on: :collection, path: "restaurar"
    end
  end
  resource :settings, path: "ajustes", only: %i[ show update ] do
    post :backup
    patch :keys, path: "chaves"
    post :test_openrouter, path: "chaves/testar-openrouter"
    post :test_gmail, path: "chaves/testar-gmail"
    post :regenerate_token, path: "chaves/token"
  end
  resource :onboarding, path: "primeiro-uso", only: :show do
    post :finish, path: "concluir"
  end
  resource :profile, path: "perfil", only: %i[ show update ] do
    match :preview, via: %i[ post patch ]
    get :cv, path: "curriculo"
    post :upload_cv, path: "curriculo"
    post :draft, path: "rascunho"
    delete :discard_draft, path: "rascunho"
    resource :suggestions, only: [], controller: "profile_suggestions", path: "sugestoes" do
      post :apply, path: "aplicar"
      post :dismiss, path: "dispensar"
    end
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
  get "metricas" => "metrics#show", as: :metrics
  resources :consultancies, only: :update
  resources :activated_alerts, only: %i[create destroy]
  resources :message_templates, path: "mensagens", except: :show
  resource :routine, only: :show, path: "rotina" do
    post "itens/:key", action: :toggle, as: :toggle
  end

  namespace :api do
    namespace :v1 do
      resources :job_postings, only: :create do
        get :lookup, on: :collection
      end
      resources :contacts, only: :create do
        get :lookup, on: :collection
      end
      get "ping", to: "pings#show"
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboard#show"
end
