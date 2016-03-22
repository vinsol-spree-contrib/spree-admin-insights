class CreateSpreePageEvents < ActiveRecord::Migration
  def change
    create_table :spree_page_events do |t|
      t.references :actor, polymorphic: true
      t.references :target, polymorphic: true
      t.string :activity
      t.string :referrer
      t.string :search_keywords
      t.string :session_id
      t.timestamps null: false
    end
  end
end
