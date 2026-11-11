require "rails_helper"

RSpec.describe "Products::Images" do
  let(:seller) { create(:user) }
  let(:product) do
    create(:product, seller: seller).tap { |p| p.images.attach(Array.new(3) { image_blob }) }
  end

  describe "DELETE /products/:product_id/images/:id (#10 AC7)" do
    it "removes the image and its file from storage" do
      sign_in seller
      image = product.images.first
      blob = image.blob

      delete product_image_path(product, image)

      expect(product.reload.images.count).to eq(2)
      expect(ActiveStorage::Blob.exists?(blob.id)).to be(false)
      expect(blob.service.exist?(blob.key)).to be(false)
    end

    it "refuses when the product is not editable" do
      sign_in seller
      product.update_column(:status, Product.statuses[:pending_review])

      delete product_image_path(product, product.images.first)

      expect(product.reload.images.count).to eq(3)
    end

    it "returns 404 for another user" do
      sign_in create(:user)

      delete product_image_path(product, product.images.first)

      expect(response).to have_http_status(:not_found)
      expect(product.reload.images.count).to eq(3)
    end
  end
end
