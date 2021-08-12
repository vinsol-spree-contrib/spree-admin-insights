require 'csv'
require 'tempfile'

module Spree
  class ReportGenerationService

    CSV_OPTIONS = {
      row_sep: "\n",
      col_sep: ',',
      quote_char: '"',
      skip_blanks: true,
      empty_value: nil,
      strip: true,
      field_size_limit: 16384,
      encoding: 'r:bom|utf-8'
    }.freeze

    class << self
      delegate :reports, :report_exists?, :reports_for_category, :default_report_category, to: :configuration
      delegate :configuration, to: SpreeAdminInsights::Config
    end

    def initialize(report)
      @report = report
    end

    def self.generate_report(report_name, options)
      klass = Spree.const_get((report_name.to_s + '_report').classify)
      resource = klass.new(options)
      dataset = resource.generate
    end

    def download
      headers = @report.headers
      stats = @report.observations
      
      CSV.open(tmp_file.path, "wb", **CSV_OPTIONS) do |csv_file|
        csv_file << headers.map { |head| head[:name] }
        stats.each do |record|
          csv_file << headers.map { |head| record.public_send(head[:value]) }
        end
      end
      tmp_file
    end

    private def tmp_file
      @tmp_file ||= Tempfile.new('report')
    end

  end
end
