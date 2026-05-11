require 'rails_helper'

RSpec.describe "Core::Dashboard", type: :request do
  describe "GET /dashboard" do
    context "when not signed in" do
      it "redirects to sign in" do
        get core_dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      let(:user) { create(:user) }

      before { sign_in user }

      it "is accessible" do
        get core_dashboard_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
