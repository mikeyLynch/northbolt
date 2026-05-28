require "rails_helper"

RSpec.describe "Core::Settings", type: :request do
  let(:user)     { create(:user) }
  let(:business) { user.business }

  before { sign_in user }

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
end
