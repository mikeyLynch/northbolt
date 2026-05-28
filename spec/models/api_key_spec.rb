require "rails_helper"

RSpec.describe ApiKey, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:digest) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:business) }
  end

  describe ".generate" do
    let(:business) { create(:business) }

    it "creates an ApiKey record" do
      expect { ApiKey.generate(business: business, name: "Test") }.to change(ApiKey, :count).by(1)
    end

    it "returns the key and a token" do
      key, token = ApiKey.generate(business: business, name: "Test")
      expect(key).to be_a(ApiKey)
      expect(token).to match(/\Anb_\d+_[a-f0-9]{48}\z/)
    end

    it "stores a SHA256 digest of the secret, not the secret itself" do
      key, token = ApiKey.generate(business: business, name: "Test")
      secret = token.split("_").last
      expect(key.digest).to eq(Digest::SHA256.hexdigest(secret))
      expect(key.digest).not_to eq(secret)
    end

    it "associates the key with the correct business" do
      key, = ApiKey.generate(business: business, name: "Test")
      expect(key.business).to eq(business)
    end
  end

  describe ".authenticate" do
    let(:business) { create(:business) }
    let(:key)      { create(:api_key, business: business, digest: Digest::SHA256.hexdigest("secret123")) }
    let(:token)    { "nb_#{key.id}_secret123" }

    it "returns the business for a valid token" do
      expect(ApiKey.authenticate(token)).to eq(business)
    end

    it "updates last_used_at on success" do
      expect { ApiKey.authenticate(token) }.to change { key.reload.last_used_at }.from(nil)
    end

    it "returns nil for a wrong secret" do
      expect(ApiKey.authenticate("nb_#{key.id}_wrongsecret")).to be_nil
    end

    it "returns nil for an unknown key id" do
      expect(ApiKey.authenticate("nb_0_secret123")).to be_nil
    end

    it "returns nil for a malformed token" do
      expect(ApiKey.authenticate("not-a-token")).to be_nil
      expect(ApiKey.authenticate("")).to be_nil
      expect(ApiKey.authenticate(nil)).to be_nil
    end

    it "returns nil for a revoked key" do
      key.revoke!
      expect(ApiKey.authenticate(token)).to be_nil
    end
  end

  describe "#revoke!" do
    let(:key) { create(:api_key) }

    it "sets revoked_at" do
      expect { key.revoke! }.to change { key.revoked_at }.from(nil)
    end

    it "makes the key inactive" do
      key.revoke!
      expect(key).not_to be_active
    end
  end
end
