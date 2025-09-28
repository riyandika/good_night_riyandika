module Api
  module V1
    class UsersController < BaseController
      include Paginatable

      # GET /api/v1/users
      def index
        render json: paginate_collection(User.all, UserSerializer)
      end

      # GET /api/v1/users/:id
      def show
        user = User.find(params[:id])
        render json: user, serializer: UserSerializer
      end
    end
  end
end