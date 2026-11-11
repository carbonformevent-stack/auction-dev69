class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.references :seller, null: false, foreign_key: { to_table: :users }, index: false
      t.integer :category, null: false
      t.integer :starting_price, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.integer :desired_duration_minutes, null: false, default: 1440
      t.integer :status, null: false, default: 0
      t.datetime :submitted_at

      t.timestamps
    end

    add_index :products, %i[seller_id updated_at]
    add_index :products, %i[status submitted_at]

    add_check_constraint :products, "starting_price BETWEEN 1 AND 20000", name: "products_starting_price_range"
    add_check_constraint :products, "desired_duration_minutes BETWEEN 60 AND 10080", name: "products_desired_duration_range"
    add_check_constraint :products, "category IN (0, 1, 2, 3)", name: "products_category_valid"
    add_check_constraint :products, "status IN (0, 1, 2, 3)", name: "products_status_valid"
  end
end
