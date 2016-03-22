class AddCartEvent < ActiveRecord::Migration
  def change
    create_table :spree_cart_events do |t|
      t.references :actor, polymorphic: true
      t.references :target, polymorphic: true
      t.string :activity
      t.string :referrer
      t.integer :quantity
      t.decimal :total, precision: 16, scale: 4
      t.string :session_id
      t.timestamps null: false
    end
  end
end
