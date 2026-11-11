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
    save_product(failure: :new, saved_notice: "บันทึกสินค้าแบบร่างแล้ว")
  end

  def edit; end

  def update
    @product.assign_attributes(product_params)
    save_product(failure: :edit, saved_notice: "บันทึกการแก้ไขแล้ว")
  end

  def destroy
    unless @product.destroyable_by?(current_user)
      return redirect_to @product, alert: "ลบได้เฉพาะสินค้าแบบร่าง"
    end

    @product.destroy!
    redirect_to products_path, notice: "ลบสินค้าแล้ว", status: :see_other
  end

  private

  # ปุ่ม "ส่งตรวจสอบ" ในฟอร์มส่ง submit_for_review → บันทึกแล้วส่งตรวจในครั้งเดียว
  # ปุ่ม "บันทึกฉบับร่าง" แค่บันทึก (สถานะไม่เปลี่ยน)
  def save_product(failure:, saved_notice:)
    if params[:submit_for_review].present?
      save_and_submit(failure)
    elsif @product.save
      redirect_to @product, notice: saved_notice
    else
      render failure, status: :unprocessable_content
    end
  end

  # ตรวจด้วย context :submit ก่อนบันทึก — ถ้าไม่ผ่านจะไม่สร้าง/แก้อะไรเลย
  def save_and_submit(failure)
    Product.transaction do
      raise ActiveRecord::RecordInvalid, @product unless @product.valid?(:submit)

      @product.save!
      Products::Submit.call(product: @product, user: current_user)
    end
    redirect_to products_path, notice: Products::Submit.notice(@product)
  rescue ActiveRecord::RecordInvalid
    render failure, status: :unprocessable_content
  rescue Product::InvalidTransition => e
    redirect_to products_path, alert: e.message
  end

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
