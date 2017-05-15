module Spree
  class UsersWhoRecentlyPurchasedReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :user_email
    HEADERS = { user_email: :string, purchase_count: :integer, last_purchase_date: :date, last_purchased_order_number: :string }
    SEARCH_ATTRIBUTES = { start_date: :start_date, end_date: :end_date, email_cont: :email }
    SORTABLE_ATTRIBUTES = [:user_email, :purchase_count, :last_purchase_date]

    def initialize(options)
      super
      @email_cont = @search[:email_cont].present? ? "%#{ @search[:email_cont] }%" : '%'
      set_sortable_attributes(options, DEFAULT_SORTABLE_ATTRIBUTE)
    end

    def generate(options = {})
      case DBUtils.adapter
        when :postgresql
          generate_from_postgresql
        else
          generate_from_mysql
      end
    end

    def select_columns(dataset)
      case DBUtils.adapter
        when :postgresql
          select_columns_postgresql(dataset)
        else
          select_columns_mysql(dataset)
      end
    end

    private

    def generate_from_postgresql
      all_orders_with_users = SpreeAdminInsights::ReportDb[:spree_orders___orders]
                                .join(:spree_users___users, id: :user_id)
                                .where(orders__completed_at: @start_date..@end_date)
                                .where(Sequel.ilike(:users__email, @email_cont))
                                .select(Sequel.lit("COUNT(*) AS purchase_count"))
                                .select_append { [
        Sequel.as(:users__email, :user_email),
        Sequel.as(Sequel.function(:MIN, :orders__completed_at), :last_purchase_date)
      ] }.group(:users__email).order(Sequel.desc(:last_purchase_date))
                                .as(:all_orders_with_users)

      SpreeAdminInsights::ReportDb[all_orders_with_users]
        .left_join(:spree_orders___orders, email: :user_email)
        .distinct(:user_email)
        .select { [Sequel.as(:all_orders_with_users, :user_email)] }
    end

    def select_columns_postgresql(dataset)
      results = dataset.select { [
        :user_email,
        :all_orders_with_users__purchase_count,
        :all_orders_with_users__last_purchase_date,
        Sequel.as(:orders__number, :last_purchased_order_number)
      ] }

      SpreeAdminInsights::ReportDb[results].order(sortable_sequel_expression)
    end

    def generate_from_mysql
      all_orders_with_users = SpreeAdminInsights::ReportDb[:spree_users___users].
        left_join(:spree_orders___orders, user_id: :id).
        where(orders__completed_at: @start_date..@end_date).
        where(Sequel.ilike(:users__email, @email_cont)).
        order(Sequel.desc(:orders__completed_at)).
        select(
          :users__email___user_email,
          :orders__number___last_purchased_order_number,
          :orders__completed_at___last_purchase_date,
        ).as(:all_orders_with_users)

      SpreeAdminInsights::ReportDb[all_orders_with_users].
        group(:all_orders_with_users__user_email).
        order(sortable_sequel_expression)
    end

    def select_columns_mysql(dataset)
      dataset.select { [
        all_orders_with_users__user_email,
        all_orders_with_users__last_purchased_order_number,
        all_orders_with_users__last_purchase_date,
        count(all_orders_with_users__user_email).as(purchase_count)
      ] }
    end
  end
end
