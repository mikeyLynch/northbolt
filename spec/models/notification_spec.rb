require 'rails_helper'

RSpec.describe Notification, type: :model do
  subject { build(:notification) }

  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to belong_to(:notifiable).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:notification_type) }
  end

  describe "scopes" do
    let(:business) { create(:business) }

    it "unread returns only notifications without read_at" do
      unread = create(:notification, business: business, read_at: nil)
      create(:notification, business: business, read_at: Time.current)
      expect(Notification.unread).to contain_exactly(unread)
    end

    it "recent returns the latest 20 ordered by created_at desc" do
      21.times { create(:notification, business: business) }
      expect(Notification.recent.count).to eq(20)
      expect(Notification.recent).to eq(Notification.order(created_at: :desc).limit(20).to_a)
    end
  end

  describe "#read?" do
    it "returns false when read_at is nil" do
      expect(build(:notification, read_at: nil).read?).to be false
    end

    it "returns true when read_at is set" do
      expect(build(:notification, read_at: Time.current).read?).to be true
    end
  end

  describe "#mark_read!" do
    it "sets read_at" do
      notification = create(:notification, read_at: nil)
      notification.mark_read!
      expect(notification.reload.read_at).to be_present
    end

    it "does not update read_at if already read" do
      time = 1.hour.ago
      notification = create(:notification, read_at: time)
      notification.mark_read!
      expect(notification.reload.read_at).to be_within(1.second).of(time)
    end
  end
end
