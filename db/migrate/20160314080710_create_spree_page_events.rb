class CreateSpreePageEvents < ActiveRecord::Migration
  def change
    create_table :spree_page_events do |t|
      t.belongs_to :actor, polymorphic: true, index: true
      t.belongs_to :target, polymorphic: true, index: true
      t.string :activity
      t.string :referrer
      t.string :search_keywords
      t.string :session_id
      t.string :query_string
      t.timestamps null: false
    end
  end
end
