module Spree
  class Report

    attr_accessor :sortable_attribute, :sortable_type, :total_records,
                  :records_per_page, :current_page, :paginate, :search, :reporting_period, :search_name
    alias_method  :sort_direction, :sortable_type
    alias_method  :paginate?, :paginate


    TIME_SCALES = [:hourly, :daily, :monthly, :yearly]

    def paginated?
      false
    end

    def pagination_required?
      paginated? && paginate?
    end

    def deeplink_properties
      {
        deeplinked: false
      }
    end

    def self.deeplink(template_for_headers = {})
      define_method :deeplink_properties do
        { deeplinked: true }.merge(template_for_headers)
      end
    end

    def generate(options = {})
      self.class::Result.new do |report|
        report.start_date = @start_date
        report.end_date   = @end_date
        report.time_scale = @time_scale
        report.report = self
      end
    end

    def initialize(options)
      self.search = options.fetch(:search, {})
      self.records_per_page = options[:records_per_page]
      self.current_page = options[:offset]
      self.paginate = options[:paginate]
      extract_reporting_period
      determine_report_time_scale
      extract_search_name
      if self.class::SORTABLE_ATTRIBUTES.present?
        set_sortable_attributes(options, self.class::DEFAULT_SORTABLE_ATTRIBUTE)
      end
    end

    def header_sorted?(header)
      sortable_attribute.present? && sortable_attribute.eql?(header)
    end

    def get_results
      query =
        if pagination_required?
          paginated_report_query
        else
          report_query
        end

      query = query.order(active_record_sort) if sortable_attribute.present?
      query_sql = query.to_sql
      ActiveRecord::Base.connection.exec_query(query_sql)
    end

    def set_sortable_attributes(options, default_sortable_attribute)
      self.sortable_type ||= (options[:sort] && options[:sort][:type].eql?('desc')) ? :desc : :asc
      self.sortable_attribute = options[:sort] ? options[:sort][:attribute].to_sym : default_sortable_attribute
    end

    def active_record_sort
      "#{ sortable_attribute } #{ sortable_type }"
    end

    def total_records
      ActiveRecord::Base.connection.select_value(record_count_query.to_sql).to_i
    end

    def total_pages
      if pagination_required?
        total_pages = total_records / records_per_page
        total_pages -= 1 if total_records % records_per_page == 0
        total_pages
      end
    end

    def time_scale_selects(time_scale_on = nil)
      QueryTimeScale.select(@time_scale, time_scale_on)
    end

    def time_scale_selects_from_column(time_scale_on, column_name)
      QueryTimeScale.select_with_column_name(@time_scale, time_scale_on, column_name)
    end

    def time_scale_columns
      @_time_scale_columns ||= QueryTimeScale.time_scale_columns(@time_scale)
    end

    def time_scale_columns_to_s
      @_time_scale_columns_to_s ||= time_scale_columns.collect(&:to_s)
    end

    def name
      @_report_name ||= self.class.to_s.demodulize.underscore.gsub("_report", "")
    end

    private def extract_reporting_period
      start_date = @search[:start_date]
      @start_date = start_date.present? ? Date.parse(start_date) :  Date.current.beginning_of_year
      end_date = @search[:end_date]
      @end_date = (end_date.present? ? Date.parse(end_date) : Date.current.end_of_year)
      self.reporting_period = (@start_date.beginning_of_day)..(@end_date.end_of_day)
    end

    private def extract_search_name
      @name = search[:name].present? ? "%#{ search[:name] }%" : '%'
      self.search_name = @name
    end

    private def determine_report_time_scale
      @time_scale =
        case (@end_date - @start_date).to_i
        when 0..1
          :hourly
        when 1..60
          :daily
        when 61..600
          :monthly
        else
          :yearly
        end
    end

  end
end
