module Api
  module V1
    class SleepRecordsController < BaseController
      include Paginatable
      before_action :set_current_user

      # POST /api/v1/users/:user_id/sleep_records
      def create
        in_progress_record = @current_user.sleep_records
          .in_progress
          .first

        if in_progress_record
          # clock out, set wake_up_at
          in_progress_record.wake_up_at = Time.current
          in_progress_record.save!

          render json: {
            message: "Successfully clocked out",
            sleep_record: SleepRecordSerializer.new(in_progress_record)
          }, status: :ok
        else
          # clock in, create new sleep record with sleep_at
          @current_user.sleep_records.create!(sleep_at: Time.current)
          render json: {
            message: "Successfully clocked in",
            sleep_record: SleepRecordSerializer.new(@current_user.sleep_records.last)
          }, status: :created
        end
      end

      # GET /api/v1/users/:user_id/sleep_records
      def index
        records = @current_user.sleep_records.recent
        render json: paginate_collection(records, SleepRecordSerializer)
      end

      # GET /api/v1/users/:user_id/sleep_records/friends_sleep_records
      def friends_sleep_records
        # Get all users that current user is following
        following_users = @current_user.following

        # Get previous week's date range (7 days ago to now)
        one_week_ago = 1.week.ago

        # Get all sleep records from following users in the past week
        friends_records = fetch_friends_sleep_records(following_users, one_week_ago)

        # Format response
        render json: paginate_collection(friends_records, SleepRecordSerializer)
      end

      private

      def fetch_friends_sleep_records(following_users, one_week_ago)
        SleepRecord
          .joins(:user)
          .where(user: following_users)
          .where(sleep_at: one_week_ago..Time.current)
          .completed
          .includes(:user)
          .order(duration_in_seconds: :desc)
      end
    end
  end
end
