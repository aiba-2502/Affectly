module Api
  module V1
    class ReportsController < ApplicationController
      before_action :authorize_request

      def show
        report_service = ReportService.new(current_user)
        report_data = report_service.generate_report

        render json: report_data
      end

      def weekly
        report_service = ReportService.new(current_user)
        weekly_report = report_service.generate_weekly_report

        render json: weekly_report
      end

      def monthly
        report_service = ReportService.new(current_user)
        monthly_report = report_service.generate_monthly_report

        render json: monthly_report
      end
    end
  end
end