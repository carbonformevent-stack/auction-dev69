# ผู้ขายจัดการสินค้าของตัวเอง — ค้นหาผ่าน current_user.products เสมอ (สินค้าของคนอื่น = 404)
class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]
  before_action :ensure_editable, only: %i[edit update]

  def index
    owned = current_user.products
    @status_counts = owned.group(:status).count
    @status = Product.statuses.key?(params[:status].to_s) ? params[:status].to_s : nil

    scope = @status ? owned.where(status: @status) : owned
    @products = scope.includes(:reviews).with_attached_images.with_attached_certificate.order(updated_at: :desc)
  end

  def show; end

  def new
    @product = current_user.products.build
  end

  def create
    @product = current_user.products.build(product_params)

    if @product.save
      redirect_to @product, notice: "บันทึกสินค้าแบบร่างแล้ว"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "บันทึกการแก้ไขแล้ว"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    unless @product.destroyable_by?(current_user)
      return redirect_to @product, alert: "ลบได้เฉพาะสินค้าแบบร่าง"
    end

    @product.destroy!
    redirect_to products_path, notice: "ลบสินค้าแล้ว", status: :see_other
  end

  private

  def set_product
    @product = current_user.products.includes(:reviews).find(params[:id])
  end

  def ensure_editable
    return if @product.editable_by?(current_user)

    redirect_to @product, alert: @product.edit_blocked_reason
  end

  def product_params
    params.expect(product: [ :category, :starting_price, :title, :description,
                             :desired_duration_minutes, :certificate, images: [] ])
  end
end
