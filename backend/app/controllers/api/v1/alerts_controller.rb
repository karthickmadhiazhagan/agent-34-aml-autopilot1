module Api
  module V1
    class AlertsController < ApplicationController
      # GET /api/v1/alerts
      def index
        alerts = Alert
          .includes(:customer, :account)
          .order(created_at: :desc)

        render json: {
          alerts: alerts.map(&:as_summary),
          total:  alerts.size
        }
      end

      # GET /api/v1/alerts/:id
      def show
        alert = Alert.includes(:customer, :account).find_by!(alert_id: params[:id].upcase)

        # Include any existing investigations for this alert
        investigations = Investigation
          .where(alert_id: params[:id].upcase)
          .order(created_at: :desc)
          .map { |i| { id: i.id, status: i.status, created_at: i.created_at } }

        render json: { alert: alert.as_alert_data, investigations: investigations }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Alert #{params[:id]} not found" }, status: :not_found
      end
    end
  end
end
