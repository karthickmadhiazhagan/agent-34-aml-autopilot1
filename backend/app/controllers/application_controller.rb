class ApplicationController < ActionController::API
  rescue_from StandardError, with: :render_internal_error
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_not_found(e)
    render json: { error: e.message }, status: :not_found
  end

  def render_internal_error(e)
    Rails.logger.error "[#{e.class}] #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
    render json: { error: e.message }, status: :internal_server_error
  end
end
