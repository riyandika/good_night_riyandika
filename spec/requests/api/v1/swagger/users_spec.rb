require 'swagger_helper'

RSpec.describe 'api/v1/users', type: :request do
  path '/api/v1/users' do
    get('List users') do
      tags 'Users'
      description 'Get a paginated list of all users'
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

        let(:page) { 1 }
        let(:per_page) { 10 }

        before do
          create_list(:user, 25)
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['data']).to be_an(Array)
          expect(data['pagination']).to be_present
        end
      end
    end
  end

  path '/api/v1/users/{id}' do
    parameter name: 'id', in: :path, type: :integer, description: 'User ID'

    get('Show user') do
      tags 'Users'
      description 'Get details of a specific user'

      response(200, 'successful') do
        schema '$ref' => '#/components/schemas/User'

        let(:user) { create(:user) }
        let(:id) { user.id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['id']).to eq(user.id)
          expect(data['name']).to eq(user.name)
        end
      end

      response(404, 'not found') do
        schema '$ref' => '#/components/schemas/Error'

        let(:id) { 999999 }

        run_test!
      end
    end
  end
end
