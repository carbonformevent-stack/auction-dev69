require "rails_helper"

RSpec.describe "Products::Certificates" do
  let(:seller) { create(:user) }
  let(:product) do
    create(:product, :with_image, seller: seller).tap { |p| p.certificate.attach(fixture_upload("certificate.pdf")) }
  end

  describe "DELETE /products/:product_id/certificate" do
    it "redirects guests to sign in" do
      delete product_certificate_path(product)

      expect(response).to redirect_to(new_user_session_path)
      expect(product.reload.certificate).to be_attached
    end

    it "removes the certificate and its file from storage" do
      sign_in seller
      blob = product.certificate.blob

      delete product_certificate_path(product)

      expect(response).to redirect_to(edit_product_path(product))
      expect(product.reload.certificate).not_to be_attached
      expect(blob.service.exist?(blob.key)).to be(false)
    end

    it "works for a rejected product so the seller can fix it" do
      sign_in seller
      product.update_column(:status, Product.statuses[:rejected])

      delete product_certificate_path(product)

      expect(product.reload.certificate).not_to be_attached
    end

    %i[pending_review approved].each do |status|
      it "refuses when the product is #{status}" do
        sign_in seller
        product.update_column(:status, Product.statuses[status])

        delete product_certificate_path(product)

        expect(product.reload.certificate).to be_attached
        expect(response).to redirect_to(product_path(product))
      end
    end

    it "returns 404 for another user" do
      sign_in create(:user)

      delete product_certificate_path(product)

      expect(response).to have_http_status(:not_found)
      expect(product.reload.certificate).to be_attached
    end

    it "does nothing when there is no certificate" do
      sign_in seller
      product.certificate.purge

      delete product_certificate_path(product)

      expect(response).to redirect_to(edit_product_path(product))
    end
  end
end
