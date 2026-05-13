require "rails_helper"

RSpec.describe "Core::Tenants", type: :request do
  let(:business) { create(:business) }
  let(:user)     { create(:user, business: business) }
  let!(:tenant)  { create(:tenant, business: business, first_name: "Jane", last_name: "Smith") }

  let(:other_business) { create(:business) }
  let!(:other_tenant)  { create(:tenant, business: other_business) }

  describe "GET /tenants" do
    context "when not signed in" do
      it "redirects to sign in" do
        get core_tenants_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "is accessible" do
        get core_tenants_path
        expect(response).to have_http_status(:ok)
      end

      it "shows only tenants belonging to the user's business" do
        get core_tenants_path
        expect(response.body).to include(core_tenant_path(tenant))
        expect(response.body).not_to include(core_tenant_path(other_tenant))
      end

      it "filters by search query" do
        get core_tenants_path, params: { q: "Jane" }
        expect(response.body).to include(core_tenant_path(tenant))
      end
    end
  end

  describe "GET /tenants/:id" do
    context "when not signed in" do
      it "redirects to sign in" do
        get core_tenant_path(tenant)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "shows the tenant" do
        get core_tenant_path(tenant)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Jane Smith")
      end

      it "returns 404 for a tenant belonging to another business" do
        get core_tenant_path(other_tenant)
        expect(response).to have_http_status(:not_found)
      end

      it "shows the history tab" do
        get core_tenant_path(tenant, tab: "history")
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
