module Admin
  # ยังไม่มีหน้าภาพรวม (การจัดประมูลมาใน M2) — เข้า /admin แล้วไปคิวรอตรวจเลย
  class DashboardController < BaseController
    def show
      redirect_to admin_products_path
    end
  end
end
