require 'swagger_helper'

RSpec.describe 'api/v1/sleep_records', type: :request do
  let(:current_user) { create(:user, name: 'Current User') }
  let(:user_id) { current_user.id }

  path '/api/v1/users/{user_id}/sleep_records' do
    parameter name: 'user_id', in: :path, type: :integer, description: 'Current user ID'

    post('Clock in/out for sleep') do
      tags 'Sleep Records'
      description 'Clock in to start sleep tracking or clock out to end current sleep session'

      response(201, 'successfully clocked in') do
        schema type: :object,
               properties: {
                 message: { type: :string, example: 'Successfully clocked in' },
                 sleep_record: { '$ref' => '#/components/schemas/SleepRecord' }
               }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq('Successfully clocked in')
          expect(data['sleep_record']['wake_up_at']).to be_nil
        end
      end

      response(200, 'successfully clocked out') do
        schema type: :object,
               properties: {
                 message: { type: :string, example: 'Successfully clocked out' },
                 sleep_record: { '$ref' => '#/components/schemas/SleepRecord' }
               }

        before do
          create(:sleep_record, user: current_user, sleep_at: 2.hours.ago, wake_up_at: nil)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq('Successfully clocked out')
          expect(data['sleep_record']['wake_up_at']).to be_present
        end
      end

      response(404, 'user not found') do
        schema '$ref' => '#/components/schemas/Error'
        let(:user_id) { 999999 }
        run_test!
      end
    end

    get('List user sleep records') do
      tags 'Sleep Records'
      description 'Get a paginated list of user\'s sleep records'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number (default: 1)'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page (default: 20)'

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/SleepRecord' }
                 },
                 pagination: { '$ref' => '#/components/schemas/PaginationMeta' }
               }

        before do
          create_list(:sleep_record, 5, user: current_user, wake_up_at: Time.current)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['data']).to be_an(Array)
          expect(data['pagination']).to be_present
        end
      end

      response(404, 'user not found') do
        schema '$ref' => '#/components/schemas/Error'
        let(:user_id) { 999999 }
        run_test!
      end
    end
  end

  path '/api/v1/users/{user_id}/sleep_records/friends_sleep_records' do
    parameter name: 'user_id', in: :path, type: :integer, description: 'Current user ID'

    get('List friends sleep records') do
      tags 'Sleep Records'
      description 'Get sleep records from users that current user follows, from past week, sorted by duration'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number (default: 1)'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page (default: 20)'

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/SleepRecord' }
                 },
                 pagination: { '$ref' => '#/components/schemas/PaginationMeta' }
               }

        let(:friend) { create(:user, name: 'Friend') }

        before do
          current_user.follow(friend)
          create(:sleep_record,
                 user: friend,
                 sleep_at: 1.day.ago,
                 wake_up_at: 1.day.ago + 8.hours,
                 duration_in_seconds: 28800)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['data']).to be_an(Array)
          expect(data['pagination']).to be_present
        end
      end

      response(404, 'user not found') do
        schema '$ref' => '#/components/schemas/Error'
        let(:user_id) { 999999 }
        run_test!
      end
    end
  end
end
