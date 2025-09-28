require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  let!(:users) { create_list(:user, 25) }
  let(:user) { users.first }

  describe "GET /api/v1/users" do
    context "without pagination parameters" do
      before { get "/api/v1/users" }

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns users with pagination metadata" do
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
        expect(pagination['total_pages']).to eq(2) # 25 users, 20 per page
        expect(pagination['total_count']).to eq(25)
      end

      it "returns users with correct attributes" do
        json_response = JSON.parse(response.body)
        user_data = json_response['data'].first

        expect(user_data).to have_key('id')
        expect(user_data).to have_key('name')
        expect(user_data).to have_key('created_at')
      end
    end

    context "with pagination parameters" do
      before { get "/api/v1/users", params: { page: 2, per_page: 10 } }

      it "returns correct page and per_page" do
        json_response = JSON.parse(response.body)
        pagination = json_response['pagination']

        expect(pagination['current_page']).to eq(2)
        expect(pagination['per_page']).to eq(10)
        expect(json_response['data'].length).to eq(10)
      end
    end

    context "with invalid page parameter" do
      before { get "/api/v1/users", params: { page: 999 } }

      it "returns empty array for non-existent page" do
        json_response = JSON.parse(response.body)

        expect(response).to have_http_status(:success)
        expect(json_response['data']).to be_empty
        expect(json_response['pagination']['current_page']).to eq(999)
      end
    end
  end

  describe "GET /api/v1/users/:id" do
    context "with valid user id" do
      before { get "/api/v1/users/#{user.id}" }

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end

      it "returns the correct user" do
        json_response = JSON.parse(response.body)

        expect(json_response['id']).to eq(user.id)
        expect(json_response['name']).to eq(user.name)
        expect(json_response).to have_key('created_at')
      end
    end

    context "with invalid user id" do
      before { get "/api/v1/users/999999" }

      it "returns not found status" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("Resource not found")
      end
    end
  end
end
