require "rails_helper"

RSpec.describe "Invitations", type: :request do
  let(:business)   { create(:business) }
  let(:inviter)    { create(:user, business: business) }
  let(:invitation) { create(:invitation, business: business, invited_by: inviter) }

  describe "GET /invitations/:token" do
    it "renders the setup form for a valid pending invitation" do
      get invitation_path(invitation.token)
      expect(response).to have_http_status(:ok)
    end

    it "redirects for an unknown token" do
      get invitation_path("bad-token")
      expect(response).to redirect_to(public_root_path)
    end

    it "redirects for an already-accepted invitation" do
      invitation.update!(accepted_at: 1.hour.ago)
      get invitation_path(invitation.token)
      expect(response).to redirect_to(public_root_path)
    end
  end

  describe "POST /invitations/:token" do
    let(:valid_params) { { first_name: "Alice", last_name: "Smith", password: "password123" } }

    before { invitation } # ensure created before count is measured

    it "creates a user and signs them in" do
      expect {
        post accept_invitation_path(invitation.token), params: valid_params
      }.to change(User, :count).by(1)
    end

    it "marks the invitation as accepted" do
      post accept_invitation_path(invitation.token), params: valid_params
      expect(invitation.reload.accepted_at).not_to be_nil
    end

    it "redirects to the dashboard" do
      post accept_invitation_path(invitation.token), params: valid_params
      expect(response).to redirect_to(core_dashboard_path)
    end

    it "re-renders the form when password is blank" do
      post accept_invitation_path(invitation.token), params: valid_params.merge(password: "")
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "redirects for an unknown token" do
      post accept_invitation_path("bad-token"), params: valid_params
      expect(response).to redirect_to(public_root_path)
    end

    it "redirects for an already-accepted invitation" do
      invitation.update!(accepted_at: 1.hour.ago)
      post accept_invitation_path(invitation.token), params: valid_params
      expect(response).to redirect_to(public_root_path)
    end
  end
end
