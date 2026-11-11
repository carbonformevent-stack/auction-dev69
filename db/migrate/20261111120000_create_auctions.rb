# รอบการประมูลของสินค้า 1 ชิ้น (ดู docs/architecture/auction-design.md §2)
# - settings ใช้ json แทน jsonb เพราะใช้ SQLite
# - winner_bid_id ยังไม่มี foreign key: ตาราง bids มาใน story เสนอราคา (จะเพิ่ม FK ตอนนั้น)
class CreateAuctions < ActiveRecord::Migration[8.1]
  def change
    create_table :auctions do |t|
      t.references :product, null: false, foreign_key: true, index: false
      t.integer :auction_type, null: false, default: 0
      t.integer :starting_price, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :status, null: false, default: 0
      t.json :settings, null: false, default: {}
      t.bigint :winner_bid_id
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.timestamps

      t.check_constraint "auction_type IN (0)", name: "auctions_auction_type_valid"
      t.check_constraint "status IN (0, 1, 2, 3, 4)", name: "auctions_status_valid"
      t.check_constraint "ends_at > starts_at", name: "auctions_ends_after_start"
      t.check_constraint "starting_price BETWEEN 1 AND 20000", name: "auctions_starting_price_range"
    end

    # สินค้า 1 ชิ้น active (scheduled = 0, running = 1) ได้ครั้งละ 1 รอบ
    add_index :auctions, :product_id, unique: true, where: "status IN (0, 1)", name: "index_auctions_one_active_per_product"
    add_index :auctions, %i[product_id created_at]
    # job เปิดและปิดประมูลหา auction ที่ถึงเวลา
    add_index :auctions, %i[status starts_at]
    add_index :auctions, %i[status ends_at]
  end
end
