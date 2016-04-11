module Spree
  class UsersNotConvertedReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :orders__completed_at
    HEADERS = { user_email: :string, signup_date: :date }
    SEARCH_ATTRIBUTES = { start_date: :users_created_from, end_date: :users_created_till, email_cont: :email }
    SORTABLE_ATTRIBUTES = [:user_email, :signup_date]

    def initialize(options)
      super
      @sortable_type = :desc if options[:sort].blank?
      @email_cont = @search[:email_cont].present? ? "%#{ @search[:email_cont] }%" : '%'
    end

    def generate(options = {})
      SpreeReportify::ReportDb[:spree_users___users].
      left_join(:spree_orders___orders, user_id: :id).
      where(orders__completed_at: nil, orders__number: nil).
      where(users__created_at: @start_date..@end_date).where(Sequel.ilike(:users__email, @email_cont)). #filter by params
      order(sortable_sequel_expression)
    end

    def select_columns(dataset)
      dataset.select{[
        users__email.as(user_email),
        users__created_at.as(signup_date)
      ]}
    end
  end
end
