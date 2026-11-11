require "rails_helper"

RSpec.describe "Admin::Dashboard" do
  describe "GET /admin" do
    it "redirects guests to sign in" do
      get admin_root_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "forbids normal users" do
      sign_in create(:user)

      get admin_root_path

      expect(response).to have_http_status(:forbidden)
    end

    it "sends admins straight to the review queue" do
      sign_in create(:user, :admin)

      get admin_root_path

      expect(response).to redirect_to(admin_products_path)
    end
  end
end
