module Admin
  module Auctions
    class CancellationsController < BaseController
      def create
        auction = Auction.includes(:product).find(params[:auction_id])
        ::Auctions::Cancel.call(auction: auction)
        redirect_to admin_auctions_path, notice: "ยกเลิกการประมูล \"#{auction.product.title}\" แล้ว"
      rescue Auction::InvalidTransition => e
        redirect_to admin_auctions_path, alert: e.message
      end
    end
  end
end
