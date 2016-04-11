module Spree
  class PaymentMethodTransactionsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :payment_method_name
    HEADERS = { payment_method_name: :string, payment_count: :integer }
    SEARCH_ATTRIBUTES = { start_date: :payments_created_from, end_date: :payments_created_till }
    SORTABLE_ATTRIBUTES = [:payment_method_name, :payment_count]

    def initialize(options)
      super
      set_sortable_attributes(options, DEFAULT_SORTABLE_ATTRIBUTE)
    end

    def generate
      SpreeReportify::ReportDb[:spree_payment_methods___payment_methods].
      join(:spree_payments___payments, payment_method_id: :id).
      where(payments__created_at: @start_date..@end_date). #filter by params
      group(:payment_method_name).
      order(sortable_sequel_expression)
    end

    def select_columns(dataset)
      dataset.select{[
        payment_methods__name.as(payment_method_name),
        count(payments__payment_method_id).as(:payment_count)
      ]}
    end
  end
end
