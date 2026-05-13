require "rails_helper"

RSpec.describe "Core::Locks::AccessGrants", type: :request do
  let(:business) { create(:business) }
  let(:user)     { create(:user, business: business) }
  let(:location) { create(:location, business: business) }
  let(:lock)     { create(:lock, location: location) }
  let(:tenant)   { create(:tenant, business: business) }

  before { sign_in user }

  describe "GET /locks/:lock_id/access_grants/new" do
    it "is accessible for an unoccupied lock" do
      get new_core_lock_access_grant_path(lock)
      expect(response).to have_http_status(:ok)
    end

    it "redirects if the lock already has an active tenant" do
      create(:access_grant, lock: lock, tenant: tenant)
      get new_core_lock_access_grant_path(lock)
      expect(response).to redirect_to(core_lock_path(lock))
    end
  end

  describe "POST /locks/:lock_id/access_grants — existing tenant" do
    let(:valid_params) do
      { access_grant: { tenant_mode: "existing", tenant_id: tenant.id, ends_at: 1.month.from_now.to_date.to_s } }
    end

    it "creates a grant and redirects with PIN in flash" do
      post core_lock_access_grants_path(lock), params: valid_params
      expect(response).to redirect_to(core_lock_path(lock))
      follow_redirect!
      expect(response.body).to include("Access granted")
    end
  end

  describe "POST /locks/:lock_id/access_grants — new tenant" do
    let(:valid_params) do
      {
        access_grant: {
          tenant_mode: "new",
          first_name:  "Tom",
          last_name:   "Jones",
          email:       "tom@example.com",
          phone:       "07700900001",
          ends_at:     1.month.from_now.to_date.to_s
        }
      }
    end

    it "creates the tenant and grant, redirects with PIN in flash" do
      expect { post core_lock_access_grants_path(lock), params: valid_params }
        .to change(Tenant, :count).by(1)
        .and change(AccessGrant, :count).by(1)

      expect(response).to redirect_to(core_lock_path(lock))
      follow_redirect!
      expect(response.body).to include("Access granted")
    end
  end
end
