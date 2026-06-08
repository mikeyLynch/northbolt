require "rails_helper"

RSpec.describe "Core::Tenants::LockAssignments", type: :request do
  let(:business)  { create(:business) }
  let(:user)      { create(:user, business: business) }
  let(:location)  { create(:location, business: business) }
  let(:lock)      { create(:lock, location: location) }
  let(:tenant)    { create(:tenant, business: business) }

  before { sign_in user }

  describe "GET /tenants/:tenant_id/lock_assignments/new" do
    it "is accessible" do
      get new_core_tenant_lock_assignments_path(tenant)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /tenants/:tenant_id/lock_assignments" do
    context "with no lock selected" do
      it "re-renders the form" do
        post core_tenant_lock_assignments_path(tenant)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "sets a flash alert about selecting a lock" do
        post core_tenant_lock_assignments_path(tenant)
        expect(flash[:alert]).to include("select at least one lock")
      end

      it "does not create any access grants" do
        expect {
          post core_tenant_lock_assignments_path(tenant)
        }.not_to change(AccessGrant, :count)
      end
    end

    context "with a lock selected but no end date" do
      it "sets a flash alert about the end date" do
        post core_tenant_lock_assignments_path(tenant), params: {
          lock_assignments: { "0" => { lock_id: lock.id, starts_at: Date.current.to_s, ends_at: "" } }
        }
        expect(flash[:alert]).to include("end date")
      end
    end

    context "with a valid lock selected" do
      let(:valid_params) do
        {
          lock_assignments: {
            "0" => { lock_id: lock.id, starts_at: Date.current.to_s, ends_at: 1.month.from_now.to_date.to_s }
          }
        }
      end

      it "creates an access grant" do
        expect {
          post core_tenant_lock_assignments_path(tenant), params: valid_params
        }.to change(AccessGrant, :count).by(1)
      end

      it "redirects to the tenant with a notice" do
        post core_tenant_lock_assignments_path(tenant), params: valid_params
        expect(response).to redirect_to(core_tenant_path(tenant))
        expect(flash[:notice]).to be_present
      end
    end
  end
end
