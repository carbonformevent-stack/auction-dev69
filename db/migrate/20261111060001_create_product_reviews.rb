# ประวัติการตรวจสินค้า (audit trail) — insert อย่างเดียว ไม่มี updated_at
class CreateProductReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :product_reviews do |t|
      t.references :product, null: false, foreign_key: true, index: false
      t.references :reviewer, null: false, foreign_key: { to_table: :users }
      t.integer :decision, null: false
      t.text :reason
      t.datetime :created_at, null: false
    end

    add_index :product_reviews, %i[product_id created_at]
    add_check_constraint :product_reviews, "decision IN (0, 1)", name: "product_reviews_decision_valid"
    add_check_constraint :product_reviews, "decision <> 1 OR reason IS NOT NULL", name: "product_reviews_rejection_has_reason"
  end
end
