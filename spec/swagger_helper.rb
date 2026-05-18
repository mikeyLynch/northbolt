require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Northbolt Public API",
        version: "v1",
        description: "API for integrating with the Northbolt smart lock platform. Authenticate all requests with your API key in the Authorization header."
      },
      servers: [
        { url: "https://{host}", variables: { host: { default: "app.northbolt.io" } } }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer,
            description: "API key issued from Settings → API keys"
          }
        },
        schemas: {
          Lock: {
            type: :object,
            properties: {
              id:              { type: :integer },
              unit_identifier: { type: :string, example: "A12" },
              device_uuid:     { type: :string, format: :uuid },
              location:        { type: :string, example: "High Street facility" },
              last_seen_at:    { type: :string, format: "date-time", nullable: true },
              status:          { type: :string, enum: %w[available unavailable available_soon unavailable_soon] }
            },
            required: %w[id unit_identifier device_uuid location status]
          },
          Tenant: {
            type: :object,
            properties: {
              id:         { type: :integer },
              first_name: { type: :string },
              last_name:  { type: :string },
              email:      { type: :string, format: :email, nullable: true },
              phone:      { type: :string, nullable: true },
              created_at: { type: :string, format: "date-time" }
            },
            required: %w[id first_name last_name]
          },
          Error: {
            type: :object,
            properties: {
              error: { type: :string }
            }
          }
        }
      },
      security: [ { bearer_auth: [] } ]
    }
  }

  config.openapi_format = :yaml
end
