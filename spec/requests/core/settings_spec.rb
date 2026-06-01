require "rails_helper"

RSpec.describe "Core::Settings", type: :request do
  let(:user)     { create(:user) }
  let(:business) { user.business }

  before { sign_in user }

  describe "PATCH /settings" do
    it "updates the business name" do
      patch core_settings_general_path, params: { name: "New Name" }
      expect(business.reload.name).to eq("New Name")
    end

    it "redirects to the general tab" do
      patch core_settings_general_path, params: { name: "New Name" }
      expect(response).to redirect_to(core_settings_path(tab: "general"))
    end
  end

  describe "GET /settings" do
    it "renders the general tab by default" do
      get core_settings_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the api_keys tab" do
      get core_settings_path(tab: "api_keys")
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /settings/api_keys" do
    it "creates a new ApiKey for the business" do
      expect {
        post core_settings_api_keys_path, params: { api_key_name: "My Key" }
      }.to change(ApiKey, :count).by(1)
    end

    it "associates the key with the current business" do
      post core_settings_api_keys_path, params: { api_key_name: "My Key" }
      expect(business.api_keys.last.name).to eq("My Key")
    end

    it "flashes the one-time token" do
      post core_settings_api_keys_path, params: { api_key_name: "My Key" }
      expect(flash[:new_token]).to match(/\Anb_\d+_[a-f0-9]{48}\z/)
    end

    it "redirects to the api_keys tab" do
      post core_settings_api_keys_path, params: { api_key_name: "My Key" }
      expect(response).to redirect_to(core_settings_path(tab: "api_keys"))
    end

    context "when not signed in" do
      before { sign_out user }

      it "redirects to sign in" do
        post core_settings_api_keys_path, params: { api_key_name: "My Key" }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /settings (team tab)" do
    it "renders the team tab" do
      get core_settings_path(tab: "team")
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /settings/invitations" do
    it "creates a pending invitation" do
      expect {
        post core_settings_invitations_path, params: { email: "new@example.com" }
      }.to change(Invitation, :count).by(1)
    end

    it "associates the invitation with the current business" do
      post core_settings_invitations_path, params: { email: "new@example.com" }
      expect(business.invitations.last.email).to eq("new@example.com")
    end

    it "sets invited_by to the current user" do
      post core_settings_invitations_path, params: { email: "new@example.com" }
      expect(business.invitations.last.invited_by).to eq(user)
    end

    it "redirects to the team tab" do
      post core_settings_invitations_path, params: { email: "new@example.com" }
      expect(response).to redirect_to(core_settings_path(tab: "team"))
    end

    it "rejects an email that already has an account" do
      existing = create(:user, business: business)
      post core_settings_invitations_path, params: { email: existing.email }
      expect(response).to redirect_to(core_settings_path(tab: "team"))
      expect(flash[:alert]).to be_present
    end

    it "rejects a duplicate pending invitation" do
      create(:invitation, business: business, invited_by: user, email: "dup@example.com")
      expect {
        post core_settings_invitations_path, params: { email: "dup@example.com" }
      }.not_to change(Invitation, :count)
    end
  end

  describe "POST /settings/invitations/:id/resend" do
    let!(:invitation) { create(:invitation, business: business, invited_by: user) }

    it "regenerates the token" do
      original_token = invitation.token
      post core_resend_settings_invitation_path(invitation)
      expect(invitation.reload.token).not_to eq(original_token)
    end

    it "redirects to the team tab" do
      post core_resend_settings_invitation_path(invitation)
      expect(response).to redirect_to(core_settings_path(tab: "team"))
    end

    it "cannot resend an invitation belonging to another business" do
      other = create(:invitation)
      post core_resend_settings_invitation_path(other)
      expect(other.reload.token).to eq(other.token)
    end
  end

  describe "DELETE /settings/invitations/:id" do
    let!(:invitation) { create(:invitation, business: business, invited_by: user) }

    it "destroys the invitation" do
      expect {
        delete core_settings_invitation_path(invitation)
      }.to change(Invitation, :count).by(-1)
    end

    it "redirects to the team tab" do
      delete core_settings_invitation_path(invitation)
      expect(response).to redirect_to(core_settings_path(tab: "team"))
    end

    it "cannot cancel an invitation belonging to another business" do
      other = create(:invitation)
      expect {
        delete core_settings_invitation_path(other)
      }.not_to change(Invitation, :count)
    end
  end

  describe "DELETE /settings/members/:id" do
    let!(:member) { create(:user, business: business, role: "medium") }

    it "removes the member" do
      expect {
        delete core_settings_member_path(member)
      }.to change { business.users.count }.by(-1)
    end

    it "redirects to the team tab" do
      delete core_settings_member_path(member)
      expect(response).to redirect_to(core_settings_path(tab: "team"))
    end

    it "cannot remove yourself" do
      delete core_settings_member_path(user)
      expect(flash[:alert]).to be_present
      expect(User.exists?(user.id)).to be true
    end

    it "cannot remove a member of another business" do
      other = create(:user)
      expect {
        delete core_settings_member_path(other)
      }.not_to change(User, :count)
    end
  end

  describe "DELETE /settings/api_keys/:id" do
    let!(:api_key) { create(:api_key, business: business) }

    it "revokes the key" do
      delete core_settings_api_key_path(api_key)
      expect(api_key.reload.revoked_at).not_to be_nil
    end

    it "redirects to the api_keys tab" do
      delete core_settings_api_key_path(api_key)
      expect(response).to redirect_to(core_settings_path(tab: "api_keys"))
    end

    it "cannot revoke a key belonging to another business" do
      other_key = create(:api_key)
      delete core_settings_api_key_path(other_key)
      expect(other_key.reload.revoked_at).to be_nil
    end
  end

  describe "PATCH /settings/permissions" do
    it "updates the permission matrix as owner" do
      patch core_settings_permissions_path, params: {
        permissions: { high: ["grant_access"], medium: [], low: [] }
      }
      expect(business.reload.permission_matrix["high"]).to eq(["grant_access"])
      expect(business.reload.permission_matrix["medium"]).to eq([])
    end

    it "redirects to the permissions tab" do
      patch core_settings_permissions_path, params: { permissions: { high: [], medium: [], low: [] } }
      expect(response).to redirect_to(core_settings_path(tab: "permissions"))
    end

    it "strips unknown permissions from the matrix" do
      patch core_settings_permissions_path, params: {
        permissions: { high: ["grant_access", "fly_a_spaceship"], medium: [], low: [] }
      }
      expect(business.reload.permission_matrix["high"]).to eq(["grant_access"])
    end

    context "as a non-owner" do
      before do
        sign_out user
        sign_in create(:user, business: business, role: "high")
      end

      it "redirects to dashboard" do
        patch core_settings_permissions_path, params: { permissions: { high: [], medium: [], low: [] } }
        expect(response).to redirect_to(core_dashboard_path)
      end

      it "does not change the matrix" do
        original = business.permission_matrix.dup
        patch core_settings_permissions_path, params: { permissions: { high: [], medium: [], low: [] } }
        expect(business.reload.permission_matrix).to eq(original)
      end
    end
  end

  describe "POST /settings/invitations (with role)" do
    it "sets the role on the invitation" do
      post core_settings_invitations_path, params: { email: "new@example.com", role: "low" }
      expect(business.invitations.last.role).to eq("low")
    end

    it "defaults to medium for an invalid role" do
      post core_settings_invitations_path, params: { email: "new@example.com", role: "superadmin" }
      expect(business.invitations.last.role).to eq("medium")
    end
  end

  describe "DELETE /settings/members/:id (owner protection)" do
    let!(:owner_member) { create(:user, business: business, role: "owner") }

    it "owner can remove another owner" do
      delete core_settings_member_path(owner_member)
      expect(User.exists?(owner_member.id)).to be false
    end

    context "as a high user" do
      before do
        sign_out user
        sign_in create(:user, business: business, role: "high")
      end

      it "cannot remove an owner" do
        delete core_settings_member_path(owner_member)
        expect(flash[:alert]).to be_present
        expect(User.exists?(owner_member.id)).to be true
      end
    end
  end
end
