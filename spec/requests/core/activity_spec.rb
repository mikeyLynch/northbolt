require "rails_helper"

RSpec.describe "Core::Activity", type: :request do
  let(:business) { create(:business) }

  describe "GET /activity" do
    context "when not signed in" do
      it "redirects to sign in" do
        get core_activity_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as owner" do
      before { sign_in create(:user, business: business, role: "owner") }

      it "is accessible" do
        get core_activity_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "as high" do
      before { sign_in create(:user, business: business, role: "high") }

      it "is accessible (view_activity on by default)" do
        get core_activity_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "as low without view_activity permission" do
      before do
        matrix = business.permission_matrix.merge("low" => [])
        business.update!(permission_matrix: matrix)
        sign_in create(:user, business: business, role: "low")
      end

      it "redirects to dashboard" do
        get core_activity_path
        expect(response).to redirect_to(core_dashboard_path)
      end
    end
  end
end
