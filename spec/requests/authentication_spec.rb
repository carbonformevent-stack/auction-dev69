require "rails_helper"

RSpec.describe "Authentication" do
  describe "GET /sign_in" do
    it "shows the Keycloak login button" do
      get new_user_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("เข้าสู่ระบบด้วย Keycloak")
    end
  end

  describe "Keycloak callback" do
    it "creates the user and signs them in" do
      mock_keycloak_auth(email: "new@example.com")

      expect { get user_keycloak_omniauth_callback_path }.to change(User, :count).by(1)
      expect(response).to redirect_to(root_path)

      follow_redirect!
      expect(response.body).to include("Seller One")
    end

    it "redirects back to sign in when email is missing" do
      mock_keycloak_auth(email: nil, name: nil)

      get user_keycloak_omniauth_callback_path

      expect(response).to redirect_to(new_user_session_path)
      expect(User.count).to eq(0)
    end

    it "redirects back to sign in when Keycloak returns an error" do
      OmniAuth.config.mock_auth[:keycloak] = :invalid_credentials

      get user_keycloak_omniauth_callback_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "logs why the login failed" do
      OmniAuth.config.mock_auth[:keycloak] = :invalid_credentials
      allow(Rails.logger).to receive(:warn)

      get user_keycloak_omniauth_callback_path

      expect(Rails.logger).to have_received(:warn).with(/\[auth\] Keycloak login failed: Invalid credentials/)
    end
  end

  describe "DELETE /sign_out" do
    it "signs the user out" do
      sign_in create(:user)

      delete destroy_user_session_path
      get admin_root_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
