Deface::Override.new(virtual_path: 'spree/layouts/admin',
  name: 'add_insights_to_admin_side_menu',
  insert_bottom: '#main-sidebar > nav',
  partial: 'spree/admin/shared/insights_side_menu',
)
