require "rails_helper"

# Issue #42: กด "ออกจากระบบ" แล้วไม่ไปไหน — Turbo ส่ง form ด้วย fetch แล้วตาม redirect
# ไป Keycloak (คนละ origin) ไม่ได้เพราะ CORS ทำให้ SSO session ของ Keycloak ยังอยู่
RSpec.describe "Sign out in a browser" do
  # Keycloak ปลอม: ใช้ host "localhost" ขณะที่แอปรันที่ 127.0.0.1 → คนละ origin เหมือนของจริง
  # path นี้ไม่มีในแอป จึงได้หน้า 404 — พอให้ตรวจว่า browser ไปถึง URL logout จริง
  let(:fake_keycloak) { "http://localhost:#{Capybara.current_session.server.port}/realms/auction" }

  before do
    stub_keycloak_env(issuer: fake_keycloak)
    mock_keycloak_auth(email: "seller@example.com", id_token: "id-token-from-login")
  end

  it "leaves the app and sends the browser to Keycloak logout with id_token_hint" do
    visit new_user_session_path
    click_button "เข้าสู่ระบบด้วย Keycloak"
    find("summary[aria-label='บัญชีของฉัน']").click

    click_button "ออกจากระบบ"

    expect(page).to have_current_path(%r{\A/realms/auction/protocol/openid-connect/logout\?}, url: false)
    uri = URI(page.current_url)
    expect(uri.host).to eq("localhost")
    expect(Rack::Utils.parse_query(uri.query)).to include(
      "client_id" => "auction-web",
      "id_token_hint" => "id-token-from-login"
    )
  end
end
