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

    context "when Keycloak is configured" do
      before { stub_keycloak_env }

      def logout_params
        expect(response.location).to start_with("http://kc.test/realms/auction/protocol/openid-connect/logout?")
        Rack::Utils.parse_query(URI(response.location).query)
      end

      it "sends the id_token from login as id_token_hint so Keycloak ends the SSO session" do
        mock_keycloak_auth(id_token: "token-from-login")
        get user_keycloak_omniauth_callback_path

        delete destroy_user_session_path

        expect(logout_params).to eq(
          "client_id" => "auction-web",
          "id_token_hint" => "token-from-login",
          "post_logout_redirect_uri" => "http://www.example.com/"
        )
      end

      it "omits id_token_hint when the session has no id_token (signed in before this fix)" do
        sign_in create(:user)

        delete destroy_user_session_path

        expect(logout_params).not_to have_key("id_token_hint")
      end

      it "does not reuse the id_token after logout" do
        mock_keycloak_auth
        get user_keycloak_omniauth_callback_path
        delete destroy_user_session_path

        delete destroy_user_session_path

        expect(logout_params).not_to have_key("id_token_hint")
      end
    end

    it "renders the logout button with Turbo disabled (Keycloak is another origin)" do
      sign_in create(:user)

      get products_path

      form = Nokogiri::HTML(response.body).at_css("form[action='#{destroy_user_session_path}']")
      expect(form["data-turbo"]).to eq("false")
    end
  end
end
