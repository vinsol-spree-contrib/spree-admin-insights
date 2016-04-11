module Spree
  module Admin
    class InsightsController < Spree::Admin::BaseController
      before_action :ensure_report_exists, :set_default_pagination, only: [:show, :download]
      before_action :load_reports, only: [:index, :show]

      def index
        respond_to do |format|
          format.html
          format.json { render json: {} }
        end
      end

      def show
        @headers, @stats, @total_pages, @search_attributes, @chart_json = ReportGenerationService.generate_report(
                                              @report_name,
                                              params.merge(@pagination_hash)
                                            )

        @report_data_json = {
          current_page:      params[:page] || 0,
          headers:           @headers,
          report_type:       params[:type],
          request_path:      request.path,
          search_attributes: @search_attributes,
          stats:             @stats,
          total_pages:       @total_pages,
          url:               request.url,
          searched_fields:   params[:search],
          per_page:          @pagination_hash[:records_per_page],
          chart_json:        @chart_json
        }

        respond_to do |format|
          format.html { render :index }
          format.json { render json: @report_data_json }
        end
      end

      def download
        @headers, @stats = ReportGenerationService.generate_report(@report_name, params.merge(@pagination_hash))

        respond_to do |format|
          format.csv do
            send_data ReportGenerationService.download(@headers, @stats),
              filename: "#{ @report_name.to_s }.csv"
          end
          format.xls do
            send_data ReportGenerationService.download({ col_sep: "\t" }, @headers, @stats),
              filename: "#{ @report_name.to_s }.xls"
          end
          format.text do
            send_data ReportGenerationService.download(@headers, @stats),
              filename: "#{ @report_name.to_s }.txt"
          end
          format.pdf do
            render pdf: "#{ @report_name.to_s }",
              disposition: 'attachment',
              layout: 'spree/layouts/pdf.html'
          end
        end
      end

      private
        def ensure_report_exists
          @report_name = params[:id].to_sym
          unless ReportGenerationService::REPORTS[get_reports_type].include? @report_name
            redirect_to admin_insights_path, alert: Spree.t(:not_found, scope: [:reports])
          end
        end

        def load_reports
          @reports = ReportGenerationService::REPORTS[get_reports_type]
        end

        def get_reports_type
          params[:type] = if params[:type]
            params[:type].to_sym
          else
            session[:report_category].try(:to_sym) || ReportGenerationService::REPORTS.keys.first
          end
          session[:report_category] = params[:type]
        end

        def set_default_pagination
          @pagination_hash = {}
          if params[:no_pagination] != 'true'
            @pagination_hash[:records_per_page] = params[:per_page].try(:to_i) || Spree::Config[:records_per_page]
            @pagination_hash[:offset] = params[:page].to_i * @pagination_hash[:records_per_page]
          end
        end
    end
  end
end
