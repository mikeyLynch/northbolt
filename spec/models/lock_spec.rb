require 'rails_helper'

RSpec.describe Lock, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:location) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:unit_identifier) }
  end

  describe "#bolt_position" do
    it "returns one of Unknown, Open, or Closed" do
      expect(build(:lock).bolt_position).to be_in([ "Unknown", "Open", "Closed" ])
    end
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

  describe "#tenancy_status" do
    subject(:lock) { create(:lock) }

    it "returns 'available' when there are no grants" do
      expect(lock.tenancy_status).to eq("available")
    end

    it "returns 'available' when all grants are revoked" do
      create(:access_grant, :revoked, lock: lock)
      expect(lock.tenancy_status).to eq("available")
    end

    it "returns 'available' when all grants are expired" do
      create(:access_grant, :expired, lock: lock)
      expect(lock.tenancy_status).to eq("available")
    end

    it "returns 'available' when the next grant starts more than 1 week away" do
      create(:access_grant, lock: lock, starts_at: 8.days.from_now, ends_at: 2.months.from_now)
      expect(lock.tenancy_status).to eq("available")
    end

    it "returns 'unavailable' when there is a current active grant" do
      create(:access_grant, lock: lock, starts_at: 1.day.ago, ends_at: 2.weeks.from_now)
      expect(lock.tenancy_status).to eq("unavailable")
    end

    it "returns 'unavailable_soon' when a grant starts within 1 week" do
      create(:access_grant, lock: lock, starts_at: 3.days.from_now, ends_at: 2.months.from_now)
      expect(lock.tenancy_status).to eq("unavailable_soon")
    end

    it "returns 'unavailable_soon' when a grant starts exactly 1 week from now" do
      create(:access_grant, lock: lock, starts_at: 1.week.from_now, ends_at: 2.months.from_now)
      expect(lock.tenancy_status).to eq("unavailable_soon")
    end

    it "returns 'available_soon' when the active grant ends within 3 days" do
      create(:access_grant, lock: lock, starts_at: 1.week.ago, ends_at: 2.days.from_now)
      expect(lock.tenancy_status).to eq("available_soon")
    end

    it "returns 'available_soon' when the active grant ends exactly 3 days from now" do
      create(:access_grant, lock: lock, starts_at: 1.week.ago, ends_at: 3.days.from_now)
      expect(lock.tenancy_status).to eq("available_soon")
    end

  end
end
