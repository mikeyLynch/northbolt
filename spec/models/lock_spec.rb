require 'rails_helper'

RSpec.describe Lock, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:location) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:unit_identifier) }
  end

  describe "#probably_online?" do
    it "returns true when last_seen_at is within 10 minutes" do
      lock = build(:lock, last_seen_at: 5.minutes.ago)
      expect(lock.probably_online?).to be true
    end

    it "returns false when last_seen_at is more than 10 minutes ago" do
      lock = build(:lock, last_seen_at: 11.minutes.ago)
      expect(lock.probably_online?).to be false
    end

    it "returns false when last_seen_at is nil" do
      lock = build(:lock, last_seen_at: nil)
      expect(lock.probably_online?).to be false
    end
  end

  describe "#probably_offline?" do
    it "is the inverse of probably_online?" do
      online = build(:lock, last_seen_at: 1.minute.ago)
      offline = build(:lock, last_seen_at: 11.minutes.ago)
      expect(online.probably_offline?).to be false
      expect(offline.probably_offline?).to be true
    end
  end
end
