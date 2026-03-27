module Api
  module V1
    class InvestigationsController < ApplicationController
      before_action :set_investigation, only: [
        :show, :approve_narrative, :regenerate_narrative, :close,
        :approve_sar, :revise_sar, :export_pdf
      ]

      # GET /api/v1/investigations
      def index
        investigations = Investigation.order(created_at: :desc).map { |i| summary(i) }
        render json: { investigations: investigations }
      end

      # GET /api/v1/investigations/:id
      def show
        render json: detail(@investigation)
      end

      # POST /api/v1/investigations  { alert_id: "AML-2024-001" }
      # Returns immediately with status "running"; pipeline runs in background thread.
      def create
        alert_id = params[:alert_id]&.upcase

        # Lookup alert
        alert = Alert.includes(:customer, :account).find_by(alert_id: alert_id)
        return render json: { error: "Alert '#{alert_id}' not found" }, status: :not_found unless alert

        alert_data  = alert.as_alert_data
        ai_provider = params[:ai_provider].presence || "claude"
        investigation = Investigation.create!(
          alert_id:   alert_id,
          alert_data: alert_data.to_json,
          ai_provider: ai_provider,
          status:     "pending"
        )

        # Run the 5-agent pipeline in a background thread so the HTTP response
        # returns immediately. The frontend polls GET /investigations/:id.
        inv_id = investigation.id
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            fresh = Investigation.find(inv_id)
            InvestigationOrchestrator.new(fresh).run
          rescue => e
            begin
              Investigation.find(inv_id).failed!(e.message)
            rescue
              nil
            end
          end
        end

        render json: detail(investigation), status: :created
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # POST /api/v1/investigations/:id/approve_narrative
      # Approves the narrative and kicks off async SAR generation.
      def approve_narrative
        unless @investigation.status == "narrative_ready"
          return render json: { error: "Narrative is not ready for approval (status: #{@investigation.status})" }, status: :unprocessable_entity
        end

        @investigation.approve_narrative!(by: params[:approved_by] || "Investigator")

        # Auto-compose SAR in background thread
        inv_id = @investigation.id
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            fresh = Investigation.find(inv_id)
            InvestigationOrchestrator.new(fresh).generate_sar
          rescue => e
            begin
              Investigation.find(inv_id).failed!(e.message)
            rescue
              nil
            end
          end
        end

        @investigation.reload
        render json: { message: "Narrative approved. SAR is being generated…", investigation: detail(@investigation) }
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # POST /api/v1/investigations/:id/regenerate_narrative
      # Re-runs the Narrative + QA agents async, keeps existing evidence/patterns.
      def regenerate_narrative
        unless %w[narrative_ready narrative_approved].include?(@investigation.status)
          return render json: { error: "Cannot regenerate from status: #{@investigation.status}" }, status: :unprocessable_entity
        end

        @investigation.running!
        @investigation.increment_regeneration!

        inv_id = @investigation.id
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            fresh = Investigation.find(inv_id)
            InvestigationOrchestrator.new(fresh).regenerate_narrative
          rescue => e
            begin
              Investigation.find(inv_id).failed!(e.message)
            rescue
              nil
            end
          end
        end

        @investigation.reload
        render json: { message: "Regenerating narrative (attempt #{@investigation.regeneration_count})…", investigation: detail(@investigation) }
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # POST /api/v1/investigations/:id/close
      def close
        @investigation.close!(params[:reason] || "Closed by investigator")
        render json: { message: "Investigation closed.", investigation: detail(@investigation) }
      end

      # POST /api/v1/investigations/:id/approve_sar
      def approve_sar
        unless @investigation.status == "sar_ready"
          return render json: { error: "SAR is not ready for approval (status: #{@investigation.status})" }, status: :unprocessable_entity
        end

        @investigation.approve_sar!(by: params[:approved_by] || "Lead Investigator")
        render json: { message: "SAR approved. PDF is ready for download.", investigation: detail(@investigation) }
      end

      # POST /api/v1/investigations/:id/revise_sar
      def revise_sar
        unless %w[sar_ready sar_approved].include?(@investigation.status)
          return render json: { error: "Cannot revise SAR from status: #{@investigation.status}" }, status: :unprocessable_entity
        end

        InvestigationOrchestrator.new(@investigation).revise_sar
        @investigation.reload
        render json: { message: "SAR revised and ready for review.", investigation: detail(@investigation) }
      rescue => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # GET /api/v1/investigations/:id/export_pdf
      def export_pdf
        unless @investigation.status == "sar_approved"
          return render json: { error: "SAR must be approved before exporting PDF." }, status: :unprocessable_entity
        end

        pdf_data = SarPdfGenerator.new(@investigation).generate
        subject  = @investigation.sar_output_parsed&.dig("subject", "name") || @investigation.alert_id
        filename = "SAR_#{@investigation.alert_id}_#{Date.today}.pdf"

        send_data pdf_data,
          filename:    filename,
          type:        "application/pdf",
          disposition: "attachment"
      rescue => e
        render json: { error: "PDF generation failed: #{e.message}" }, status: :internal_server_error
      end

      private

      def set_investigation
        @investigation = Investigation.find(params[:id])
      end

      def summary(inv)
        {
          id:         inv.id,
          alert_id:   inv.alert_id,
          status:     inv.status,
          approved:   inv.sar_approved?,
          created_at: inv.created_at,
          updated_at: inv.updated_at
        }
      end

      def detail(inv)
        {
          id:                    inv.id,
          alert_id:              inv.alert_id,
          status:                inv.status,
          ai_provider:           inv.ai_provider,
          error_message:         inv.error_message,
          regeneration_count:    inv.regeneration_count,
          narrative_approved:    inv.narrative_approved?,
          narrative_approved_by: inv.narrative_approved_by,
          narrative_approved_at: inv.narrative_approved_at,
          sar_approved:          inv.sar_approved?,
          sar_approved_by:       inv.sar_approved_by,
          sar_approved_at:       inv.sar_approved_at,
          created_at:            inv.created_at,
          updated_at:            inv.updated_at,
          alert_data:            inv.alert_data_parsed,
          evidence:              inv.evidence_parsed,
          pattern_analysis:      inv.pattern_analysis_parsed,
          red_flag_mapping:      inv.red_flag_mapping_parsed,
          narrative:             inv.narrative_parsed,
          qa_result:             inv.qa_result_parsed,
          sar_output:            inv.sar_output_parsed
        }
      end
    end
  end
end
