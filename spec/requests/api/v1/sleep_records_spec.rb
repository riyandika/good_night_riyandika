require 'rails_helper'

RSpec.describe "Api::V1::SleepRecords", type: :request do
  let!(:current_user) { create(:user, name: "Current User") }
  let!(:other_user) { create(:user, name: "Other User") }

  describe "POST /api/v1/users/:user_id/sleep_records" do
    context "when user has no in-progress sleep record (clock in)" do
      before do
        post "/api/v1/users/#{current_user.id}/sleep_records"
      end

      it "returns http created status" do
        expect(response).to have_http_status(:created)
      end

      it "returns success message for clock in" do
        json_response = JSON.parse(response.body)
        
        expect(json_response['message']).to eq("Successfully clocked in")
        expect(json_response['sleep_record']).to have_key('id')
        expect(json_response['sleep_record']['user_id']).to eq(current_user.id)
        expect(json_response['sleep_record']['sleep_at']).to be_present
        expect(json_response['sleep_record']['wake_up_at']).to be_nil
      end

      it "creates a new sleep record" do
        expect(current_user.sleep_records.count).to eq(1)
        sleep_record = current_user.sleep_records.last
        expect(sleep_record.sleep_at).to be_present
        expect(sleep_record.wake_up_at).to be_nil
        expect(sleep_record.completed?).to be_falsy
      end
    end

    context "when user has an in-progress sleep record (clock out)" do
      let!(:in_progress_record) do
        create(:sleep_record, 
               user: current_user, 
               sleep_at: 2.hours.ago, 
               wake_up_at: nil)
      end

      before do
        post "/api/v1/users/#{current_user.id}/sleep_records"
      end

      it "returns http ok status" do
        expect(response).to have_http_status(:ok)
      end

      it "returns success message for clock out" do
        json_response = JSON.parse(response.body)
        
        expect(json_response['message']).to eq("Successfully clocked out")
        expect(json_response['sleep_record']).to have_key('id')
        expect(json_response['sleep_record']['id']).to eq(in_progress_record.id)
        expect(json_response['sleep_record']['wake_up_at']).to be_present
        expect(json_response['sleep_record']['duration_in_seconds']).to be_present
      end

      it "completes the existing sleep record" do
        in_progress_record.reload
        expect(in_progress_record.wake_up_at).to be_present
        expect(in_progress_record.completed?).to be_truthy
        expect(in_progress_record.duration_in_seconds).to be > 0
      end

      it "does not create a new sleep record" do
        expect(current_user.sleep_records.count).to eq(1)
      end
    end

    context "with invalid user_id" do
      before do
        post "/api/v1/users/999999/sleep_records"
      end

      it "returns not found status" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("Resource not found")
      end
    end
  end

  describe "GET /api/v1/users/:user_id/sleep_records" do
    let!(:sleep_records) { create_list(:sleep_record, 25, user: current_user, wake_up_at: Time.current) }

    context "without pagination parameters" do
      before { get "/api/v1/users/#{current_user.id}/sleep_records" }

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns paginated sleep records with metadata" do
        json_response = JSON.parse(response.body)
        
        expect(json_response).to have_key('data')
        expect(json_response).to have_key('pagination')
        expect(json_response['data']).to be_an(Array)
        expect(json_response['data'].length).to eq(20) # default per_page
      end

      it "returns pagination metadata" do
        json_response = JSON.parse(response.body)
        pagination = json_response['pagination']
        
        expect(pagination['current_page']).to eq(1)
        expect(pagination['per_page']).to eq(20)
        expect(pagination['total_pages']).to eq(2) # 25 records, 20 per page
        expect(pagination['total_count']).to eq(25)
      end

      it "returns sleep records with correct attributes" do
        json_response = JSON.parse(response.body)
        sleep_record_data = json_response['data'].first
        
        expect(sleep_record_data).to have_key('id')
        expect(sleep_record_data).to have_key('user_id')
        expect(sleep_record_data).to have_key('sleep_at')
        expect(sleep_record_data).to have_key('wake_up_at')
        expect(sleep_record_data).to have_key('duration_in_seconds')
        expect(sleep_record_data).to have_key('created_at')
        expect(sleep_record_data['user_id']).to eq(current_user.id)
      end

      it "returns records in recent order (newest first)" do
        json_response = JSON.parse(response.body)
        records = json_response['data']
        
        # Check that records are sorted by created_at desc (most recent first)
        expect(records.first['id']).to eq(sleep_records.last.id)
      end
    end

    context "with pagination parameters" do
      before { get "/api/v1/users/#{current_user.id}/sleep_records", params: { page: 2, per_page: 10 } }

      it "returns correct page and per_page" do
        json_response = JSON.parse(response.body)
        pagination = json_response['pagination']
        
        expect(pagination['current_page']).to eq(2)
        expect(pagination['per_page']).to eq(10)
        expect(json_response['data'].length).to eq(10)
      end
    end

    context "when user has no sleep records" do
      let!(:user_with_no_records) { create(:user) }

      before { get "/api/v1/users/#{user_with_no_records.id}/sleep_records" }

      it "returns empty array" do
        json_response = JSON.parse(response.body)
        
        expect(response).to have_http_status(:success)
        expect(json_response['data']).to be_empty
        expect(json_response['pagination']['total_count']).to eq(0)
      end
    end

    context "with invalid user_id" do
      before { get "/api/v1/users/999999/sleep_records" }

      it "returns not found status" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("Resource not found")
      end
    end
  end

  describe "GET /api/v1/users/:user_id/sleep_records/friends_sleep_records" do
    let!(:friend1) { create(:user, name: "Friend 1") }
    let!(:friend2) { create(:user, name: "Friend 2") }
    let!(:non_friend) { create(:user, name: "Non Friend") }

    before do
      # Make current_user follow friend1 and friend2, but not non_friend
      current_user.follow(friend1)
      current_user.follow(friend2)
    end

    context "when friends have sleep records in the past week" do
      let!(:friend1_records) do
        [
          create(:sleep_record, user: friend1, sleep_at: 2.days.ago, wake_up_at: 2.days.ago + 8.hours, duration_in_seconds: 28800),
          create(:sleep_record, user: friend1, sleep_at: 4.days.ago, wake_up_at: 4.days.ago + 7.hours, duration_in_seconds: 25200)
        ]
      end

      let!(:friend2_records) do
        [
          create(:sleep_record, user: friend2, sleep_at: 1.day.ago, wake_up_at: 1.day.ago + 9.hours, duration_in_seconds: 32400)
        ]
      end

      let!(:non_friend_record) do
        create(:sleep_record, user: non_friend, sleep_at: 1.day.ago, wake_up_at: 1.day.ago + 8.hours, duration_in_seconds: 28800)
      end

      let!(:old_record) do
        create(:sleep_record, user: friend1, sleep_at: 2.weeks.ago, wake_up_at: 2.weeks.ago + 8.hours, duration_in_seconds: 28800)
      end

      before { get "/api/v1/users/#{current_user.id}/sleep_records/friends_sleep_records" }

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns paginated friends sleep records" do
        json_response = JSON.parse(response.body)
        
        expect(json_response).to have_key('data')
        expect(json_response).to have_key('pagination')
        expect(json_response['data']).to be_an(Array)
      end

      it "only includes records from followed users" do
        json_response = JSON.parse(response.body)
        user_ids = json_response['data'].map { |record| record['user_id'] }.uniq
        
        expect(user_ids).to include(friend1.id)
        expect(user_ids).to include(friend2.id)
        expect(user_ids).not_to include(non_friend.id)
      end

      it "only includes completed records from the past week" do
        json_response = JSON.parse(response.body)
        records = json_response['data']
        
        # Should have 3 records total (2 from friend1, 1 from friend2)
        expect(records.length).to eq(3)
        
        # Should not include the old record or non-friend record
        record_ids = records.map { |r| r['id'] }
        expect(record_ids).not_to include(old_record.id)
        expect(record_ids).not_to include(non_friend_record.id)
      end

      it "orders records by duration descending" do
        json_response = JSON.parse(response.body)
        records = json_response['data']
        
        durations = records.map { |r| r['duration_in_seconds'] }
        expect(durations).to eq(durations.sort.reverse)
        
        # Friend2's 9-hour record should be first (32400 seconds)
        expect(records.first['duration_in_seconds']).to eq(32400)
        expect(records.first['user_id']).to eq(friend2.id)
      end

      it "returns sleep records with correct attributes" do
        json_response = JSON.parse(response.body)
        sleep_record_data = json_response['data'].first
        
        expect(sleep_record_data).to have_key('id')
        expect(sleep_record_data).to have_key('user_id')
        expect(sleep_record_data).to have_key('sleep_at')
        expect(sleep_record_data).to have_key('wake_up_at')
        expect(sleep_record_data).to have_key('duration_in_seconds')
        expect(sleep_record_data).to have_key('created_at')
      end
    end

    context "when friends have no sleep records in the past week" do
      before { get "/api/v1/users/#{current_user.id}/sleep_records/friends_sleep_records" }

      it "returns empty array" do
        json_response = JSON.parse(response.body)
        
        expect(response).to have_http_status(:success)
        expect(json_response['data']).to be_empty
        expect(json_response['pagination']['total_count']).to eq(0)
      end
    end

    context "when user follows no one" do
      let!(:user_with_no_follows) { create(:user) }

      before { get "/api/v1/users/#{user_with_no_follows.id}/sleep_records/friends_sleep_records" }

      it "returns empty array" do
        json_response = JSON.parse(response.body)
        
        expect(response).to have_http_status(:success)
        expect(json_response['data']).to be_empty
        expect(json_response['pagination']['total_count']).to eq(0)
      end
    end

    context "with invalid user_id" do
      before { get "/api/v1/users/999999/sleep_records/friends_sleep_records" }

      it "returns not found status" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("Resource not found")
      end
    end

    context "with pagination parameters" do
      let!(:friend_with_many_records) { create(:user, name: "Sleepy Friend") }
      let!(:many_records) { create_list(:sleep_record, 25, user: friend_with_many_records, wake_up_at: Time.current) }

      before do
        current_user.follow(friend_with_many_records)
        get "/api/v1/users/#{current_user.id}/sleep_records/friends_sleep_records", params: { page: 2, per_page: 10 }
      end

      it "returns correct pagination" do
        json_response = JSON.parse(response.body)
        pagination = json_response['pagination']
        
        expect(pagination['current_page']).to eq(2)
        expect(pagination['per_page']).to eq(10)
        expect(json_response['data'].length).to eq(10)
      end
    end
  end
end