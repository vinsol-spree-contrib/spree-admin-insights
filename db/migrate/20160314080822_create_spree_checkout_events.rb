class CreateSpreeCheckoutEvents < ActiveRecord::Migration
  def change
    create_table :spree_checkout_events do |t|
      t.belongs_to :actor, polymorphic: true, index: true
      t.belongs_to :target, polymorphic: true, index: true
      t.string :activity
      t.string :referrer
      t.string :previous_state
      t.string :next_state
      t.string :session_id
      t.timestamps null: false
    end
  end
end
