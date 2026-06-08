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

  describe "GET /tenants/new" do
    context "when not signed in" do
      it "redirects to sign in" do
        get new_core_tenant_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    it "is accessible when signed in" do
      sign_in user
      get new_core_tenant_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /tenants" do
    before { sign_in user }

    context "with valid params" do
      it "creates the tenant and redirects to show" do
        expect {
          post core_tenants_path, params: { tenant: { first_name: "Alice", last_name: "Jones", email: "alice@example.com", phone: "" } }
        }.to change { business.tenants.count }.by(1)

        expect(response).to redirect_to(core_tenant_path(business.tenants.last))
      end
    end

    context "with invalid params" do
      it "re-renders new with unprocessable entity" do
        post core_tenants_path, params: { tenant: { first_name: "", last_name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "sets a flash alert" do
        post core_tenants_path, params: { tenant: { first_name: "", last_name: "" } }
        expect(flash[:alert]).to be_present
      end
    end

    context "with lock assignments" do
      let(:location) { create(:location, business: business) }
      let(:lock)     { create(:lock, location: location) }

      it "creates access grants for assigned locks" do
        expect {
          post core_tenants_path, params: {
            tenant: { first_name: "Alice", last_name: "Jones", email: "", phone: "" },
            lock_assignments: { "0" => { lock_id: lock.id, starts_at: Date.current.to_s, ends_at: 1.month.from_now.to_s } }
          }
        }.to change { AccessGrant.count }.by(1)
      end

      it "creates a grant for each lock when pin_mode is shared" do
        lock2 = create(:lock, location: location)

        expect {
          post core_tenants_path, params: {
            tenant: { first_name: "Alice", last_name: "Jones", email: "", phone: "" },
            pin_mode: "shared",
            lock_assignments: {
              "0" => { lock_id: lock.id,  starts_at: Date.current.to_s, ends_at: 1.month.from_now.to_s },
              "1" => { lock_id: lock2.id, starts_at: Date.current.to_s, ends_at: 1.month.from_now.to_s }
            }
          }
        }.to change { AccessGrant.count }.by(2)
      end
    end
  end

  describe "GET /tenants/:id/edit" do
    before { sign_in user }

    it "shows the edit form" do
      get edit_core_tenant_path(tenant)
      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for another business's tenant" do
      get edit_core_tenant_path(other_tenant)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /tenants/:id" do
    before { sign_in user }

    it "updates the tenant and redirects to show" do
      patch core_tenant_path(tenant), params: { tenant: { first_name: "Janet" } }
      expect(response).to redirect_to(core_tenant_path(tenant))
      expect(tenant.reload.first_name).to eq("Janet")
    end

    it "flashes a success notice on update" do
      patch core_tenant_path(tenant), params: { tenant: { first_name: "Janet" } }
      expect(flash[:notice]).to eq("Tenant updated.")
    end

    it "re-renders edit with unprocessable entity on invalid params" do
      patch core_tenant_path(tenant), params: { tenant: { first_name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "sets a flash alert on invalid params" do
      patch core_tenant_path(tenant), params: { tenant: { first_name: "" } }
      expect(flash[:alert]).to be_present
    end

    it "cannot update another business's tenant" do
      patch core_tenant_path(other_tenant), params: { tenant: { first_name: "Hacked" } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /tenants/:id" do
    before { sign_in user }

    it "cannot delete another business's tenant" do
      expect {
        delete core_tenant_path(other_tenant)
      }.not_to change { other_business.tenants.count }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "permission enforcement" do
    let(:low_user) do
      matrix = business.permission_matrix.merge("low" => ["view_activity"])
      business.update!(permission_matrix: matrix)
      create(:user, business: business, role: "low")
    end

    before { sign_in low_user }

    it "blocks creating a tenant without manage_tenants" do
      post core_tenants_path, params: { tenant: { first_name: "X", last_name: "Y" } }
      expect(response).to redirect_to(core_dashboard_path)
    end

    it "blocks editing a tenant without manage_tenants" do
      get edit_core_tenant_path(tenant)
      expect(response).to redirect_to(core_dashboard_path)
    end

    it "blocks deleting a tenant without manage_tenants" do
      delete core_tenant_path(tenant)
      expect(response).to redirect_to(core_dashboard_path)
    end

    it "still allows viewing a tenant (show is always accessible)" do
      get core_tenant_path(tenant)
      expect(response).to have_http_status(:ok)
    end
  end
end
