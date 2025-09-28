# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Good Night API',
        version: 'v1',
        description: 'Sleep tracking API with social features - clock in/out, track sleep records, and see friends\' sleep patterns.',
        contact: {
          name: 'API Support',
          email: 'support@goodnight.com'
        }
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        },
        {
          url: 'https://{defaultHost}',
          variables: {
            defaultHost: {
              default: 'api.goodnight.com'
            }
          },
          description: 'Production server'
        }
      ],
      components: {
        schemas: {
          User: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              name: { type: :string, example: 'John Doe' },
              created_at: { type: :string, format: :datetime, example: '2025-09-11T07:56:47Z' }
            },
            required: %w[id name created_at]
          },
          SleepRecord: {
            type: :object,
            properties: {
              id: { type: :integer, example: 1 },
              user_id: { type: :integer, example: 1 },
              sleep_at: { type: :string, format: :datetime, example: '2025-09-29T22:00:00Z' },
              wake_up_at: { type: :string, format: :datetime, example: '2025-09-30T06:00:00Z', nullable: true },
              duration_in_seconds: { type: :integer, example: 28800, nullable: true },
              created_at: { type: :string, format: :datetime, example: '2025-09-29T22:00:00Z' }
            },
            required: %w[id user_id sleep_at created_at]
          },
          PaginationMeta: {
            type: :object,
            properties: {
              current_page: { type: :integer, example: 1 },
              per_page: { type: :integer, example: 20 },
              total_pages: { type: :integer, example: 5 },
              total_count: { type: :integer, example: 100 }
            }
          },
          Error: {
            type: :object,
            properties: {
              error: { type: :string, example: 'Resource not found' }
            }
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  # Defaults to json. Accepts ':json' and ':yaml'.
  config.openapi_format = :yaml
end
