require "rails_helper"

RSpec.describe "Core::AccessGrants", type: :request do
  let(:business) { create(:business) }
  let(:user)     { create(:user, business: business) }
  let(:location) { create(:location, business: business) }
  let(:lock)     { create(:lock, location: location) }
  let(:tenant)   { create(:tenant, business: business) }
  let!(:grant)   { create(:access_grant, lock: lock, tenant: tenant, starts_at: 1.day.ago, ends_at: 1.month.from_now) }

  let(:other_business) { create(:business) }
  let(:other_location) { create(:location, business: other_business) }
  let(:other_lock)     { create(:lock, location: other_location) }
  let(:other_tenant)   { create(:tenant, business: other_business) }
  let!(:other_grant)   { create(:access_grant, lock: other_lock, tenant: other_tenant) }

  before { sign_in user }

  describe "GET /access_grants/:id/edit" do
    it "is accessible for a grant belonging to this business" do
      get edit_core_access_grant_path(grant)
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for another business's grant" do
      get edit_core_access_grant_path(other_grant)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /access_grants/:id" do
    context "with valid dates" do
      it "updates the grant and redirects" do
        new_ends_at = 2.months.from_now.to_date
        patch core_access_grant_path(grant), params: {
          access_grant: { starts_at: grant.starts_at.to_date.to_s, ends_at: new_ends_at.to_s }
        }
        expect(response).to redirect_to(core_lock_path(lock))
        expect(grant.reload.ends_at.to_date).to eq(new_ends_at)
      end

      it "respects a return_to param on redirect" do
        patch core_access_grant_path(grant), params: {
          access_grant: { starts_at: grant.starts_at.to_date.to_s, ends_at: 2.months.from_now.to_date.to_s },
          return_to: core_tenant_path(tenant)
        }
        expect(response).to redirect_to(core_tenant_path(tenant))
      end
    end

    context "when ends_at is before starts_at" do
      it "re-renders the edit form with unprocessable content" do
        patch core_access_grant_path(grant), params: {
          access_grant: { starts_at: 1.month.from_now.to_date.to_s, ends_at: Date.current.to_s }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "sets a flash alert" do
        patch core_access_grant_path(grant), params: {
          access_grant: { starts_at: 1.month.from_now.to_date.to_s, ends_at: Date.current.to_s }
        }
        expect(flash[:alert]).to be_present
      end

      it "shows the field-level error message" do
        patch core_access_grant_path(grant), params: {
          access_grant: { starts_at: 1.month.from_now.to_date.to_s, ends_at: Date.current.to_s }
        }
        expect(response.body).to include("must be after the start date")
      end
    end

    context "with invalid date strings" do
      it "re-renders the edit form" do
        patch core_access_grant_path(grant), params: {
          access_grant: { starts_at: "not-a-date", ends_at: "also-bad" }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    it "returns 404 for another business's grant" do
      patch core_access_grant_path(other_grant), params: {
        access_grant: { starts_at: Date.current.to_s, ends_at: 1.month.from_now.to_date.to_s }
      }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /access_grants/:id/revoke" do
    it "revokes the grant and redirects" do
      patch revoke_core_access_grant_path(grant)
      expect(grant.reload.revoked?).to be true
      expect(response).to redirect_to(core_lock_path(lock))
    end

    it "returns 404 for another business's grant" do
      patch revoke_core_access_grant_path(other_grant)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "permission enforcement" do
    let(:low_user) do
      matrix = business.permission_matrix.merge("low" => [])
      business.update!(permission_matrix: matrix)
      create(:user, business: business, role: "low")
    end

    before { sign_in low_user }

    it "blocks editing a grant without grant_access" do
      get edit_core_access_grant_path(grant)
      expect(response).to redirect_to(core_dashboard_path)
    end

    it "blocks updating a grant without grant_access" do
      patch core_access_grant_path(grant), params: {
        access_grant: { starts_at: Date.current.to_s, ends_at: 1.month.from_now.to_date.to_s }
      }
      expect(response).to redirect_to(core_dashboard_path)
    end

    it "blocks revoking a grant without revoke_access" do
      patch revoke_core_access_grant_path(grant)
      expect(response).to redirect_to(core_dashboard_path)
    end
  end
end
