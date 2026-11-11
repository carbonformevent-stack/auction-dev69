# หน้า sign in (มีแค่ปุ่มไป Keycloak) และ sign out
# sign out = ล้าง session ในระบบเรา แล้วส่งต่อไป Keycloak logout เพื่อปิด SSO session ด้วย
class SessionsController < ApplicationController
  # id_token จาก Keycloak (บันทึกตอน login ใน Users::OmniauthCallbacksController)
  ID_TOKEN_KEY = :keycloak_id_token

  skip_before_action :authenticate_user!

  def new
    redirect_to root_path if user_signed_in?
  end

  def destroy
    id_token = session.delete(ID_TOKEN_KEY) # อ่านก่อน sign_out
    sign_out(:user)
    redirect_to keycloak_logout_url(id_token), allow_other_host: true
  end

  private

  # มี id_token_hint → Keycloak ปิด SSO session แล้ว redirect กลับทันที
  # ไม่มี (เช่น session เก่าก่อนแก้) → Keycloak แสดงหน้ายืนยัน logout
  def keycloak_logout_url(id_token)
    issuer = ENV["KEYCLOAK_ISSUER"]
    return root_path if issuer.blank?

    query = {
      client_id: ENV["KEYCLOAK_CLIENT_ID"],
      id_token_hint: id_token.presence,
      post_logout_redirect_uri: root_url
    }.compact.to_query
    "#{issuer.chomp('/')}/protocol/openid-connect/logout?#{query}"
  end
end
