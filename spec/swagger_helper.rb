require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "public/v1/swagger.yaml" => {
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
    },
    "private/v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Northbolt Private API",
        version: "v1",
        description: "Internal API used by Northbolt lock hardware. Not for public use."
      },
      servers: [
        { url: "https://{host}", variables: { host: { default: "app.northbolt.io" } } }
      ],
      components: {
        securitySchemes: {
          lock_auth: {
            type: :apiKey,
            in: :header,
            name: "X-Signature",
            description: "Base64-encoded Ed25519 signature over (raw request body + X-Timestamp). Must be paired with X-Device-UUID and X-Timestamp headers."
          }
        },
        schemas: {
          AccessEvent: {
            type: :object,
            properties: {
              event_type:  {
                type: :string,
                enum: AccessEvent::TYPES,
                example: "pin_accepted"
              },
              occurred_at: { type: :string, format: "date-time", example: "2026-05-18T14:32:11Z" }
            },
            required: %w[event_type occurred_at]
          },
          Grant: {
            type: :object,
            properties: {
              id:             { type: :integer },
              pin_ciphertext: { type: :string, description: "PIN encrypted with the lock's public key" },
              starts_at:      { type: :string, format: "date-time" },
              ends_at:        { type: :string, format: "date-time" }
            },
            required: %w[id pin_ciphertext starts_at ends_at]
          },
          HeartbeatResponse: {
            type: :object,
            properties: {
              received_at: { type: :string, format: "date-time" },
              grant: {
                nullable: true,
                allOf: [ { "$ref" => "#/components/schemas/Grant" } ],
                description: "The currently active grant, or null if the unit is unoccupied."
              }
            },
            required: %w[received_at grant]
          },
          Error: {
            type: :object,
            properties: {
              error: { type: :string }
            }
          }
        }
      },
      security: []
    }
  }

  config.openapi_format = :yaml
end
