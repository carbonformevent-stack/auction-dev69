require "rails_helper"

RSpec.describe "Dev login on the sign in page" do
  it "is not shown outside development, even when DEV_LOGIN=1 is set" do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("DEV_LOGIN").and_return("1")

    get new_user_session_path

    expect(response.body).not_to include("ล็อกอินทดสอบ")
  end

  it "keeps the normal Keycloak button" do
    get new_user_session_path

    expect(response.body).to include("เข้าสู่ระบบด้วย Keycloak")
  end
end
