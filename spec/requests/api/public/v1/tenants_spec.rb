require "swagger_helper"

RSpec.describe "Api::Public::V1::Tenants", type: :request, openapi_spec: "public/v1/swagger.yaml" do
  let(:business)      { create(:business, api_key_digest: Digest::SHA256.hexdigest("testkey")) }
  let(:Authorization) { "Bearer nb_#{business.id}_testkey" }

  before { business }

  path "/api/public/v1/tenants" do
    get "List all tenants" do
      tags "Tenants"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      response "200", "tenants returned" do
        schema type: :array, items: { "$ref" => "#/components/schemas/Tenant" }

        before { create(:tenant, business: business) }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer bad-key" }
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end

    post "Create a tenant" do
      tags "Tenants"
      consumes "application/json"
      produces "application/json"
      security [ { bearer_auth: [] } ]

      parameter name: :body, in: :body, required: true, schema: {
        type: :object,
        properties: {
          tenant: {
            type: :object,
            properties: {
              first_name: { type: :string, example: "Jane" },
              last_name:  { type: :string, example: "Smith" },
              email:      { type: :string, format: :email, example: "jane@example.com" },
              phone:      { type: :string, example: "07700900000" }
            },
            required: %w[first_name last_name]
          }
        }
      }

      response "201", "tenant created" do
        schema "$ref" => "#/components/schemas/Tenant"
        let(:body) { { tenant: { first_name: "Jane", last_name: "Smith", email: "jane@example.com" } } }
        run_test!
      end

      response "422", "invalid parameters" do
        schema type: :object, properties: { errors: { type: :array, items: { type: :string } } }
        let(:body) { { tenant: { first_name: "", last_name: "" } } }
        run_test!
      end

      response "401", "unauthorized" do
        let(:Authorization) { "Bearer bad-key" }
        let(:body) { { tenant: { first_name: "Jane", last_name: "Smith" } } }
        schema "$ref" => "#/components/schemas/Error"
        run_test!
      end
    end
  end
end
