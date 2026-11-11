# ไม่ต่อ Keycloak จริงใน test — ใช้ OmniAuth mock แทน
OmniAuth.config.test_mode = true

module OmniAuthHelpers
  def mock_keycloak_auth(uid: "kc-123", email: "seller@example.com", name: "Seller One", id_token: "test-id-token")
    OmniAuth.config.mock_auth[:keycloak] = OmniAuth::AuthHash.new(
      provider: "keycloak",
      uid: uid,
      info: { email: email, name: name },
      credentials: { id_token: id_token }
    )
  end

  # ให้ SessionsController สร้าง Keycloak logout URL (ค่าใน test ปกติว่าง → redirect root)
  def stub_keycloak_env(issuer: "http://kc.test/realms/auction", client_id: "auction-web")
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("KEYCLOAK_ISSUER").and_return(issuer)
    allow(ENV).to receive(:[]).with("KEYCLOAK_CLIENT_ID").and_return(client_id)
  end
end

RSpec.configure do |config|
  config.include OmniAuthHelpers
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.after { OmniAuth.config.mock_auth[:keycloak] = nil }
end
