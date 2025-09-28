require 'rails_helper'

RSpec.describe "Api::V1::Follows", type: :request do
  let!(:current_user) { create(:user, name: "Current User") }
  let!(:target_user) { create(:user, name: "Target User") }
  let!(:other_users) { create_list(:user, 15) }

  describe "POST /api/v1/users/:user_id/follows" do
    let(:valid_params) { { target_user_id: target_user.id } }

    context "with valid user_id and target_user_id" do
      before do
        post "/api/v1/users/#{current_user.id}/follows", params: valid_params
      end

      it "returns http created status" do
        expect(response).to have_http_status(:created)
      end

      it "returns success message" do
        json_response = JSON.parse(response.body)
        
        expect(json_response['message']).to eq("Successfully followed user")
        expect(json_response['follow']).to have_key('id')
        expect(json_response['follow']['name']).to eq(target_user.name)
      end

      it "creates a follow relationship" do
        expect(current_user.following?(target_user)).to be_truthy
        expect(Follow.count).to eq(1)
      end
    end

    context "when trying to follow the same user twice" do
      before do
        current_user.follow(target_user)
        post "/api/v1/users/#{current_user.id}/follows", params: valid_params
      end

      it "returns unprocessable entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("Unable to follow user")
      end

      it "does not create duplicate follow relationship" do
        expect(Follow.count).to eq(1)
      end
    end

    context "when trying to follow oneself" do
      let(:self_follow_params) { { target_user_id: current_user.id } }

      before do
        post "/api/v1/users/#{current_user.id}/follows", params: self_follow_params
      end

      it "returns unprocessable entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("Unable to follow user")
      end

      it "does not create follow relationship" do
        expect(Follow.count).to eq(0)
      end
    end

    context "with invalid user_id" do
      before do
        post "/api/v1/users/999999/follows", params: valid_params
      end

      it "returns not found status" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("Resource not found")
      end
    end

    context "with invalid target_user_id" do
      let(:invalid_params) { { target_user_id: 999999 } }

      before do
        post "/api/v1/users/#{current_user.id}/follows", params: invalid_params
      end

      it "returns not found status" do
        expect(response).to have_http_status(:not_found)
      end
    end

    context "without user_id parameter" do
      before do
        post "/api/v1/users//follows", params: valid_params
      end

      it "returns not found status (route doesn't match)" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /api/v1/users/:user_id/follows" do
    let!(:followed_users) { create_list(:user, 25) }

    before do
      # Make current_user follow some users
      followed_users.each { |user| current_user.follow(user) }
    end

    context "without pagination parameters" do
      before { get "/api/v1/users/#{current_user.id}/follows" }

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns followings with pagination metadata" do
        json_response = JSON.parse(response.body)
        
        expect(json_response).to have_key('followings')
        expect(json_response).to have_key('pagination')
        expect(json_response['followings']).to be_an(Array)
        expect(json_response['followings'].length).to eq(20) # default per_page
      end

      it "returns correct pagination metadata" do
        json_response = JSON.parse(response.body)
        pagination = json_response['pagination']
        
        expect(pagination['current_page']).to eq(1)
        expect(pagination['per_page']).to eq(20)
        expect(pagination['total_pages']).to eq(2) # 25 followed users, 20 per page
        expect(pagination['total_count']).to eq(25)
      end

      it "returns users with correct attributes" do
        json_response = JSON.parse(response.body)
        following_data = json_response['followings'].first
        
        expect(following_data).to have_key('id')
        expect(following_data).to have_key('name')
        expect(following_data).to have_key('created_at')
      end
    end

    context "with pagination parameters" do
      before { get "/api/v1/users/#{current_user.id}/follows", params: { page: 2, per_page: 15 } }

      it "returns correct page and per_page" do
        json_response = JSON.parse(response.body)
        pagination = json_response['pagination']
        
        expect(pagination['current_page']).to eq(2)
        expect(pagination['per_page']).to eq(15)
        expect(json_response['followings'].length).to eq(10) # 25 total - 15 on first page = 10 on second
      end
    end

    context "with invalid user_id" do
      before { get "/api/v1/users/999999/follows" }

      it "returns not found status" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("Resource not found")
      end
    end

    context "when user has no followings" do
      let!(:user_with_no_follows) { create(:user) }

      before { get "/api/v1/users/#{user_with_no_follows.id}/follows" }

      it "returns empty array" do
        json_response = JSON.parse(response.body)
        
        expect(response).to have_http_status(:success)
        expect(json_response['followings']).to be_empty
        expect(json_response['pagination']['total_count']).to eq(0)
      end
    end
  end

  describe "DELETE /api/v1/users/:user_id/follows/:target_user_id" do
    before do
      # Create a follow relationship
      current_user.follow(target_user)
    end

    context "with valid user_id and target_user_id" do
      before do
        delete "/api/v1/users/#{current_user.id}/follows/#{target_user.id}"
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns success message" do
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq("Successfully unfollowed user")
      end

      it "removes the follow relationship" do
        expect(current_user.following?(target_user)).to be_falsy
        expect(Follow.count).to eq(0)
      end
    end

    context "when trying to unfollow a user not being followed" do
      let!(:non_followed_user) { create(:user) }

      before do
        delete "/api/v1/users/#{current_user.id}/follows/#{non_followed_user.id}"
      end

      it "returns unprocessable entity status" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("Unable to unfollow user")
      end
    end

    context "with invalid user_id" do
      before do
        delete "/api/v1/users/999999/follows/#{target_user.id}"
      end

      it "returns not found status" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("Resource not found")
      end
    end

    context "with invalid target_user_id" do
      before do
        delete "/api/v1/users/#{current_user.id}/follows/999999"
      end

      it "returns not found status" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end