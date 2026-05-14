require "rails_helper"

RSpec.describe "Core::Tenants::AccessGrants", type: :request do
  let(:business)  { create(:business) }
  let(:user)      { create(:user, business: business) }
  let(:location)  { create(:location, business: business) }
  let(:lock)      { create(:lock, location: location) }
  let(:tenant)    { create(:tenant, business: business) }

  before { sign_in user }

  describe "GET /tenants/:tenant_id/access_grants/new" do
    it "is accessible" do
      get new_core_tenant_access_grant_path(tenant)
      expect(response).to have_http_status(:ok)
    end

    it "only shows locks with no active grant" do
      lock # ensure created before the request
      occupied_lock = create(:lock, location: location)
      create(:access_grant, lock: occupied_lock, tenant: tenant)

      get new_core_tenant_access_grant_path(tenant)
      expect(response.body).to include("value=\"#{lock.id}\"")
      expect(response.body).not_to include("value=\"#{occupied_lock.id}\"")
    end
  end

  describe "POST /tenants/:tenant_id/access_grants" do
    let(:valid_params) do
      { access_grant: { lock_id: lock.id, ends_at: 1.month.from_now.to_date.to_s } }
    end

    it "creates a grant and redirects with the PIN in flash" do
      post core_tenant_access_grants_path(tenant), params: valid_params
      expect(response).to redirect_to(core_tenant_path(tenant, tab: "history"))
      follow_redirect!
      expect(response.body).to include("Access granted")
    end

    it "does not grant access to an already occupied lock" do
      create(:access_grant, lock: lock, tenant: create(:tenant, business: business))
      post core_tenant_access_grants_path(tenant), params: valid_params
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
