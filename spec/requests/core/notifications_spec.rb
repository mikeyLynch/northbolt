require 'rails_helper'

RSpec.describe "Core::Notifications", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /notifications" do
    it "returns ok" do
      get core_notifications_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /notifications/unread_count" do
    it "returns the unread count as JSON" do
      create(:notification, business: user.business, read_at: nil)
      get core_notifications_unread_count_path
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["count"]).to eq(1)
    end
  end

  describe "PATCH /notifications/:id/read" do
    it "marks the notification as read" do
      notification = create(:notification, business: user.business, read_at: nil)
      patch core_notification_read_path(notification)
      expect(notification.reload.read_at).to be_present
    end
  end

  describe "PATCH /notifications/read_all" do
    it "marks all unread notifications as read" do
      create_list(:notification, 3, business: user.business, read_at: nil)
      patch core_notifications_read_all_path
      expect(user.business.notifications.unread.count).to eq(0)
    end
  end
end
