# ไม่ต่อ Keycloak จริงใน test — ใช้ OmniAuth mock แทน
OmniAuth.config.test_mode = true

module OmniAuthHelpers
  def mock_keycloak_auth(uid: "kc-123", email: "seller@example.com", name: "Seller One")
    OmniAuth.config.mock_auth[:keycloak] = OmniAuth::AuthHash.new(
      provider: "keycloak",
      uid: uid,
      info: { email: email, name: name }
    )
  end
end

RSpec.configure do |config|
  config.include OmniAuthHelpers
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.after { OmniAuth.config.mock_auth[:keycloak] = nil }
end
