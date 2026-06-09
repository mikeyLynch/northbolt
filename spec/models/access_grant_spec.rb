require "rails_helper"

RSpec.describe AccessGrant, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:lock) }
    it { is_expected.to belong_to(:tenant) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:pin_ciphertext) }
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_presence_of(:ends_at) }

    it "is invalid when ends_at is before starts_at" do
      grant = build(:access_grant, starts_at: 1.week.from_now, ends_at: Date.current)
      expect(grant).not_to be_valid
      expect(grant.errors[:ends_at]).to include("must be after the start date")
    end

    it "is invalid when ends_at equals starts_at" do
      t = Time.current
      grant = build(:access_grant, starts_at: t, ends_at: t)
      expect(grant).not_to be_valid
      expect(grant.errors[:ends_at]).to include("must be after the start date")
    end

    it "prevents a second active grant on the same lock" do
      lock = create(:lock)
      create(:access_grant, lock: lock)
      duplicate = build(:access_grant, lock: lock)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:lock]).to include("already has an active access grant")
    end

    it "allows a new grant on a lock whose previous grant was revoked" do
      lock = create(:lock)
      create(:access_grant, :revoked, lock: lock)
      new_grant = build(:access_grant, lock: lock)
      expect(new_grant).to be_valid
    end
  end

  describe "scopes" do
    let(:lock) { create(:lock) }

    it ".active returns grants without a revoked_at" do
      active = create(:access_grant, lock: lock)
      expect(AccessGrant.active).to include(active)
    end

    it ".revoked returns grants with a revoked_at" do
      revoked = create(:access_grant, :revoked, lock: create(:lock))
      expect(AccessGrant.revoked).to include(revoked)
    end

    it ".expired returns active grants past their ends_at" do
      expired = create(:access_grant, :expired, lock: create(:lock))
      expect(AccessGrant.expired).to include(expired)
    end
  end

  describe ".issue!" do
    it "creates a grant and returns it with the plaintext PIN" do
      lock   = create(:lock)
      tenant = create(:tenant)
      grant, pin = AccessGrant.issue!(lock: lock, tenant: tenant, ends_at: 1.month.from_now)

      expect(grant).to be_persisted
      expect(pin).to match(/\A\d{4}\z/)
    end

    it "stores the PIN in pin_ciphertext" do
      lock   = create(:lock)
      tenant = create(:tenant)
      grant, pin = AccessGrant.issue!(lock: lock, tenant: tenant, ends_at: 1.month.from_now)

      expect(grant.pin_ciphertext).to eq(pin)
    end

    it "uses the supplied pin when one is provided" do
      lock   = create(:lock)
      tenant = create(:tenant)
      grant, pin = AccessGrant.issue!(lock: lock, tenant: tenant, ends_at: 1.month.from_now, pin: "1234")

      expect(pin).to eq("1234")
      expect(grant.pin_ciphertext).to eq("1234")
    end
  end

  describe "#active? / #revoked?" do
    it "is active when revoked_at is nil" do
      grant = build(:access_grant)
      expect(grant.active?).to be true
      expect(grant.revoked?).to be false
    end

    it "is revoked when revoked_at is set" do
      grant = build(:access_grant, :revoked)
      expect(grant.active?).to be false
      expect(grant.revoked?).to be true
    end
  end

  describe "#revoke!" do
    it "sets revoked_at" do
      grant = create(:access_grant)
      expect { grant.revoke! }.to change { grant.revoked_at }.from(nil)
      expect(grant.revoked?).to be true
    end
  end
end
