module Spree
  class UserPoolReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :orders__completed_at
    HEADERS = { months_name: :string, guest_users: :integer, active_users: :integer, new_sign_ups: :integer }
    SEARCH_ATTRIBUTES = { start_date: :users_created_from, end_date: :users_created_till }
    SORTABLE_ATTRIBUTES = []

    def no_pagination?
      true
    end

    def generate(options = {})
      # order of column is important when we take union of two tables
      new_sign_ups = SpreeReportify::ReportDb[:spree_users___users].
      where(users__created_at: @start_date..@end_date).
      select{[
        id.as(:user_id),
        Sequel.as(YEAR(:users__created_at), :year),
        Sequel.as(MONTHNAME(:users__created_at), :month_name),
        Sequel.as(MONTH(:users__created_at), :number)
      ]}

      group_new_sign_ups_by_months = SpreeReportify::ReportDb[new_sign_ups].
      group(:year, :number, :months_name, :guest_users, :active_users).
      order(:year, :number).
      select{[
        number,
        year,
        Sequel.as(concat(month_name, ' ', IFNULL(year, 2016)), :months_name),
        Sequel.as(0, :guest_users),
        Sequel.as(0, :active_users),
        Sequel.as(IFNULL(COUNT(user_id), 0), :new_sign_ups)
      ]}

      vistors = SpreeReportify::ReportDb[:spree_page_events___page_events].
      where(page_events__created_at: @start_date..@end_date).
      select{[
        Sequel.as(YEAR(:page_events__created_at), :year),
        Sequel.as(MONTHNAME(:page_events__created_at), :month_name),
        Sequel.as(MONTH(:page_events__created_at), :number),
        Sequel.as(actor_id, :user),
        Sequel.as(session_id, :session)
      ]}

      visitors_by_months = SpreeReportify::ReportDb[vistors].
      group(:year, :number, :months_name, :new_sign_ups).
      order(:year, :number).
      select{[
        number,
        year,
        Sequel.as(concat(month_name, ' ', IFNULL(year, 2016)), :months_name),
        Sequel.as((COUNT(DISTINCT session) - COUNT(DISTINCT user)), :guest_users),
        Sequel.as(COUNT(DISTINCT user), :active_users),
        Sequel.as(0, :new_sign_ups)
      ]}

      union_of_stats = group_new_sign_ups_by_months.union(visitors_by_months)

      union_stats = SpreeReportify::ReportDb[union_of_stats].
      group(:year, :number, :months_name).
      order(:year, :number).
      select{[
        months_name,
        year,
        number,
        Sequel.as(SUM(:guest_users), :guest_users),
        Sequel.as(SUM(:active_users), :active_users),
        Sequel.as(SUM(:new_sign_ups), :new_sign_ups)
      ]}

      fill_missing_values({guest_users: 0, active_users: 0, new_sign_ups: 0}, union_stats.all)
    end

    def select_columns(dataset)
      dataset
    end

    # extract it in report.rb
    def chart_data
      unless @data
        @data = Hash.new {|h, k| h[k] = [] }
        generate.each do |object|
          object.each_pair do |key, value|
            @data[key].push(value)
          end
        end
      end
      @data
    end

    def chart_json
      {
        chart: true,
        charts: [
          {
            id: 'user-pool',
            json: {
              chart: { type: 'column' },
              title: {
                useHTML: true,
                text: '<span class="chart-title">User Pool</span><span class="glyphicon glyphicon-question-sign" data-toggle="tooltip" title=" Keep a track of different type of users such as guest users, registered users and newly signed up users"></span>'
                },
              xAxis: { categories: chart_data[:months_name] },
              yAxis: {
                title: { text: 'Count' }
              },
              legend: {
                  layout: 'vertical',
                  align: 'right',
                  verticalAlign: 'middle',
                  borderWidth: 0
              },
              series: [
                {
                  name: Spree.t('user_pool.new_sign_ups'),
                  data: chart_data[:new_sign_ups].map(&:to_i)
                },
                {
                  name: Spree.t('user_pool.active_users'),
                  data: chart_data[:active_users].map(&:to_i)
                },
                {
                  name: Spree.t('user_pool.guest_users'),
                  data: chart_data[:guest_users].map(&:to_i)
                }
              ]
            }
          }
        ]
      }
    end
  end
end
