require "swagger_helper"

RSpec.describe "Api::Public::V1::Locks", type: :request, openapi_spec: "public/v1/swagger.yaml" do
  let(:business)  { create(:business) }
  let(:location)  { create(:location, business: business) }
  let(:lock)      { create(:lock, location: location) }
  let(:api_key)   { create(:api_key, business: business) }
  let(:Authorization) { "Bearer nb_#{api_key.id}_testkey" }

  before { lock; api_key }

  path "/api/public/v1/locks" do
    get "List all locks" do
      tags "Locks"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :available, in: :query, schema: { type: :boolean }, required: false,
                description: "When true, returns only locks with no active or upcoming tenant"

      response "200", "locks returned" do
        schema type: :array, items: { "$ref" => "#/components/schemas/Lock" }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer bad-key" }
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end
  end

  path "/api/public/v1/locks/{id}" do
    get "Get a lock" do
      tags "Locks"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :id, in: :path, type: :integer, required: true

      response "200", "lock returned" do
        let(:id) { lock.id }
        schema "$ref" => "#/components/schemas/Lock"
        run_test!
      end

      response "404", "lock not found" do
        let(:id) { 0 }
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end

      response "401", "unauthorized" do
        let(:id) { lock.id }
        let(:Authorization) { "Bearer bad-key" }
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end
  end
end
