require "swagger_helper"

RSpec.describe "Api::Private::V1::Heartbeats", type: :request, openapi_spec: "private/v1/swagger.yaml" do
  let(:signing_key) { RbNaCl::Signatures::Ed25519::SigningKey.generate }
  let(:lock) do
    create(:lock,
      device_uuid: SecureRandom.uuid,
      public_key:  Base64.strict_encode64(signing_key.verify_key.to_bytes)
    )
  end

  let(:timestamp)       { Time.current.iso8601 }
  let(:"X-Device-UUID") { lock.device_uuid }
  let(:"X-Timestamp")   { timestamp }

  before { lock }

  path "/api/private/v1/heartbeat" do
    post "Send heartbeat" do
      tags "Heartbeat"
      consumes "application/json"
      produces "application/json"
      description "Called by the lock periodically to report status and sync active grants. " \
                  "Each request must be signed with the lock's Ed25519 private key."

      parameter name: "X-Device-UUID", in: :header, type: :string, required: true,
                description: "The lock's unique device identifier (UUID)"
      parameter name: "X-Timestamp",   in: :header, type: :string, required: true,
                description: "ISO8601 timestamp of the request. Must be within 5 minutes of server time to prevent replay attacks."
      parameter name: "X-Signature",   in: :header, type: :string, required: true,
                description: "Base64-encoded Ed25519 signature over (raw request body + X-Timestamp)"
      parameter name: :body, in: :body, required: false, schema: {
        type: :object,
        properties: {
          battery_level: {
            type: :integer,
            minimum: 0,
            maximum: 100,
            example: 87,
            description: "Battery percentage. Triggers a low battery notification to the operator at ≤20%."
          },
          events: {
            type: :array,
            maxItems: 5,
            description: "Access events queued since the last heartbeat. The lock buffers up to 5 and clears them on receipt of a 200.",
            items: { "$ref" => "#/components/schemas/AccessEvent" }
          }
        }
      }

      response "200", "heartbeat received" do
        schema "$ref" => "#/components/schemas/HeartbeatResponse"

        let(:body) do
          {
            battery_level: 87,
            events: [
              { event_type: "pin_rejected", occurred_at: 3.minutes.ago.iso8601 },
              { event_type: "pin_accepted", occurred_at: 2.minutes.ago.iso8601 }
            ]
          }
        end
        let(:"X-Signature") { Base64.strict_encode64(signing_key.sign("#{body.to_json}#{timestamp}")) }

        before do
          create(:access_grant, lock: lock, starts_at: 1.day.ago, ends_at: 1.month.from_now)
        end

        run_test!
      end

      response "401", "unauthorized" do
        schema "$ref" => "#/components/schemas/Error"

        let(:body)          { {} }
        let(:"X-Signature") { "badsignature" }

        run_test!
      end
    end
  end
end
