Rswag::Ui.configure do |c|
  c.openapi_endpoint "/api-docs/public/v1/swagger.yaml",  "Public API V1"
  c.openapi_endpoint "/api-docs/private/v1/swagger.yaml", "Private API V1 (Internal)"
end
