Rails.application.routes.draw do
  # Authentication: Keycloak (OIDC) ผ่าน Devise omniauthable — ไม่มี password ในระบบ
  devise_for :users, only: :omniauth_callbacks, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
  get "sign_in", to: "sessions#new", as: :new_user_session
  delete "sign_out", to: "sessions#destroy", as: :destroy_user_session

  # "สินค้าของฉัน" — ผู้ขายเห็นและจัดการเฉพาะสินค้าของตัวเอง
  resources :products do
    scope module: :products do
      resource :submission, only: :create
      resources :images, only: :destroy
      resource :certificate, only: :destroy
    end
  end

  namespace :admin do
    root "dashboard#show"

    # index = คิวรอตรวจ, show = หน้าตรวจสินค้า
    resources :products, only: %i[index show] do
      scope module: :products do
        resource :approval, only: :create
        resource :rejection, only: :create
        resources :auctions, only: %i[new create] # สร้างการประมูลจากสินค้าที่อนุมัติแล้ว
      end
    end

    # index = สินค้าพร้อมจัดประมูล + รอบประมูลทั้งหมด
    resources :auctions, only: :index do
      scope module: :auctions do
        resource :cancellation, only: :create
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#show"
end
