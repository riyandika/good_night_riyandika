require 'swagger_helper'

RSpec.describe 'api/v1/follows', type: :request do
  let(:current_user) { create(:user, name: 'Current User') }
  let(:target_user) { create(:user, name: 'Target User') }
  let(:user_id) { current_user.id }

  path '/api/v1/users/{user_id}/follows' do
    parameter name: 'user_id', in: :path, type: :integer, description: 'Current user ID'

    get('List user followings') do
      tags 'Follows'
      description 'Get a paginated list of users that the current user follows'
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number (default: 1)'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page (default: 20)'

      response(200, 'successful') do
        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: { '$ref' => '#/components/schemas/User' }
                 },
                 pagination: { '$ref' => '#/components/schemas/PaginationMeta' }
               }

        before do
          3.times { current_user.follow(create(:user)) }
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

    post('Follow a user') do
      tags 'Follows'
      description 'Follow another user'
      parameter name: :target_user_id, in: :query, type: :integer, required: true, description: 'ID of user to follow'

      response(201, 'successfully followed') do
        schema type: :object,
               properties: {
                 message: { type: :string, example: 'Successfully followed user' },
                 follow: { '$ref' => '#/components/schemas/User' }
               }

        let(:target_user_id) { target_user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq('Successfully followed user')
          expect(current_user.following?(target_user)).to be_truthy
        end
      end

      response(422, 'unable to follow') do
        schema '$ref' => '#/components/schemas/Error'

        let(:target_user_id) { current_user.id } # Try to follow self

        run_test!
      end

      response(404, 'user not found') do
        schema '$ref' => '#/components/schemas/Error'
        let(:target_user_id) { 999999 }
        run_test!
      end
    end
  end

  path '/api/v1/users/{user_id}/follows/{target_user_id}' do
    parameter name: 'user_id', in: :path, type: :integer, description: 'Current user ID'
    parameter name: 'target_user_id', in: :path, type: :integer, description: 'ID of user to unfollow'

    delete('Unfollow a user') do
      tags 'Follows'
      description 'Unfollow a user'

      response(200, 'successfully unfollowed') do
        schema type: :object,
               properties: {
                 message: { type: :string, example: 'Successfully unfollowed user' }
               }

        let(:target_user_id) { target_user.id }

        before do
          current_user.follow(target_user)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['message']).to eq('Successfully unfollowed user')
          expect(current_user.following?(target_user)).to be_falsy
        end
      end

      response(422, 'unable to unfollow') do
        schema '$ref' => '#/components/schemas/Error'

        let(:other_user) { create(:user) }
        let(:target_user_id) { other_user.id }

        run_test!
      end

      response(404, 'user not found') do
        schema '$ref' => '#/components/schemas/Error'
        let(:target_user_id) { 999999 }
        run_test!
      end
    end
  end
end
