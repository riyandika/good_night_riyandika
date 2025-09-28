module Api
  module V1
    class FollowsController < BaseController
      include Paginatable
      before_action :set_current_user
      before_action :set_target_user, only: [ :create, :destroy ]

      # POST /api/v1/users/:user_id/follows
      def create
        if @current_user.follow(@target_user)
          render json: {
            message: "Successfully followed user",
            follow: UserSerializer.new(@target_user)
          }, status: :created
        else
          render json: { error: "Unable to follow user" }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/users/:user_id/follows
      def index
        render json: paginate_collection(@current_user.following, UserSerializer)
      end

      # DELETE /api/v1/users/:user_id/follows/:target_user_id
      def destroy
        if @current_user.unfollow(@target_user)
          render json: { message: "Successfully unfollowed user" }
        else
          render json: { error: "Unable to unfollow user" }, status: :unprocessable_entity
        end
      end

    private
      def set_target_user
        @target_user = User.find(params[:target_user_id])

        render_not_found unless @target_user
      end
    end
  end
end
