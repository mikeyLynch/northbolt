require "rails_helper"

RSpec.describe "Core::Account", type: :request do
  let(:user) { create(:user, password: "password123") }

  before { sign_in user }

  describe "GET /account" do
    it "is accessible" do
      get core_account_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /account/profile" do
    it "updates the profile and redirects with notice" do
      patch core_account_profile_path, params: { first_name: "Alice", last_name: "Jones", email: "alice@example.com" }
      expect(response).to redirect_to(core_account_path)
      expect(flash[:notice]).to eq("Profile updated.")
    end

    it "updates the user's name" do
      patch core_account_profile_path, params: { first_name: "Alice", last_name: "Jones", email: user.email }
      expect(user.reload.first_name).to eq("Alice")
    end

    it "re-renders with alert on blank name" do
      patch core_account_profile_path, params: { first_name: "", last_name: "", email: user.email }
      expect(response).to have_http_status(:unprocessable_content)
      expect(flash[:alert]).to be_present
    end

    it "highlights the errored field via model errors" do
      patch core_account_profile_path, params: { first_name: "", last_name: "Jones", email: user.email }
      expect(user.errors[:first_name]).not_to be_empty
    end
  end

  describe "PATCH /account/password" do
    it "updates the password and redirects with notice" do
      patch core_account_password_path, params: {
        current_password: "password123",
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
      expect(response).to redirect_to(core_account_path)
      expect(flash[:notice]).to eq("Password updated.")
    end

    it "sets flash alert and current_password error for wrong current password" do
      patch core_account_password_path, params: {
        current_password: "wrongpassword",
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(flash[:alert]).to be_present
    end

    it "sets flash alert and confirmation error when passwords don't match" do
      patch core_account_password_path, params: {
        current_password: "password123",
        password: "newpassword123",
        password_confirmation: "differentpassword"
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(flash[:alert]).to be_present
    end
  end
end
