module Admin
  class DashboardController < BaseController
    def show
      @pending_count = Product.pending_review.count
    end
  end
end
