module Api
  module V1
    class AlertsController < ApplicationController
      # GET /api/v1/alerts
      def index
        alerts = DummyAlertService.all_alerts
        render json: { alerts: alerts, total: alerts.size }
      end

      # GET /api/v1/alerts/:id
      def show
        alert = DummyAlertService.find(params[:id])
        raise ActiveRecord::RecordNotFound, "Alert #{params[:id]} not found" unless alert

        # Include any existing investigations for this alert
        investigations = Investigation
          .where(alert_id: params[:id].upcase)
          .order(created_at: :desc)
          .map { |i| { id: i.id, status: i.status, created_at: i.created_at } }

        render json: { alert: alert, investigations: investigations }
      end
    end
  end
end
