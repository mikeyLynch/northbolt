require "rails_helper"

RSpec.describe Invitation, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to belong_to(:invited_by).class_name("User") }
  end

  describe "token generation" do
    it "generates a token before validation on create" do
      invitation = build(:invitation, token: nil)
      invitation.valid?
      expect(invitation.token).to be_present
    end

    it "does not overwrite an existing token on re-validation" do
      invitation = create(:invitation)
      original_token = invitation.token
      invitation.valid?
      expect(invitation.token).to eq(original_token)
    end
  end

  describe "scopes" do
    let!(:pending)  { create(:invitation) }
    let!(:accepted) { create(:invitation, :accepted) }

    it ".pending returns only uninvited invitations" do
      expect(Invitation.pending).to include(pending)
      expect(Invitation.pending).not_to include(accepted)
    end

    it ".accepted returns only accepted invitations" do
      expect(Invitation.accepted).to include(accepted)
      expect(Invitation.accepted).not_to include(pending)
    end
  end

  describe "#pending?" do
    it "returns true when not yet accepted" do
      expect(build(:invitation)).to be_pending
    end

    it "returns false when accepted" do
      expect(build(:invitation, :accepted)).not_to be_pending
    end
  end

  describe "#regenerate_token!" do
    it "replaces the token" do
      invitation = create(:invitation)
      original = invitation.token
      invitation.regenerate_token!
      expect(invitation.reload.token).not_to eq(original)
    end
  end

  describe "#accept!" do
    let(:business)    { create(:business) }
    let(:inviter)     { create(:user, business: business) }
    let!(:invitation) { create(:invitation, business: business, invited_by: inviter) }

    it "creates a user for the business" do
      expect {
        invitation.accept!(first_name: "Alice", last_name: "Smith", password: "password123")
      }.to change { business.users.count }.by(1)
    end

    it "returns the new user" do
      user = invitation.accept!(first_name: "Alice", last_name: "Smith", password: "password123")
      expect(user).to be_a(User)
      expect(user.email).to eq(invitation.email)
    end

    it "creates the user with the invitation's role" do
      invitation.update!(role: "high")
      user = invitation.accept!(first_name: "Alice", last_name: "Smith", password: "password123")
      expect(user).to be_high
    end

    it "defaults to medium role" do
      user = invitation.accept!(first_name: "Alice", last_name: "Smith", password: "password123")
      expect(user).to be_medium
    end

    it "marks the invitation as accepted" do
      invitation.accept!(first_name: "Alice", last_name: "Smith", password: "password123")
      expect(invitation.reload.accepted_at).not_to be_nil
    end

    it "raises RecordInvalid when password is blank" do
      expect {
        invitation.accept!(first_name: "Alice", last_name: "Smith", password: "")
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
