module Api
  module V1
    class BaseController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    private
      def render_not_found
        render json: { error: "Resource not found" }, status: :not_found
      end

      def set_current_user
        unless params[:user_id].present?
          render json: { error: "user_id parameter is required" }, status: :bad_request and return
        end
        @current_user = User.find_by(id: params[:user_id])
        render_not_found unless @current_user
      end
    end
  end
end
