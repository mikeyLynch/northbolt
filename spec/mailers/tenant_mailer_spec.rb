require "rails_helper"

RSpec.describe TenantMailer, type: :mailer do
  let(:business)  { create(:business, name: "Lynch Storage") }
  let(:location)  { create(:location, business: business, name: "Edinburgh West") }
  let(:tenant)    { create(:tenant, business: business, first_name: "Jane", email: "jane@example.com") }

  def make_grant(unit:, pin:)
    lock = create(:lock, location: location, unit_identifier: unit)
    create(:access_grant, lock: lock, tenant: tenant, pin_ciphertext: pin,
           starts_at: Date.new(2026, 5, 1).beginning_of_day,
           ends_at:   Date.new(2026, 8, 1).end_of_day)
  end

  describe "#access_granted" do
    context "single lock" do
      let(:grant) { make_grant(unit: "14", pin: "4821") }
      let(:mail)  { described_class.access_granted(tenant, [ grant ]) }

      it "sends to the tenant" do
        expect(mail.to).to eq [ "jane@example.com" ]
      end

      it "sends from the Northbolt address" do
        expect(mail.from).to eq [ "noreply@northbolt.co.uk" ]
      end

      it "includes the unit identifier in the subject" do
        expect(mail.subject).to include("Unit 14")
      end

      it "includes the business name in the subject" do
        expect(mail.subject).to include("Lynch Storage")
      end

      it "includes the PIN in the HTML body" do
        expect(mail.html_part.body.to_s).to include("4821")
      end

      it "includes the PIN in the text body" do
        expect(mail.text_part.body.to_s).to include("4821")
      end

      it "includes the location name" do
        expect(mail.html_part.body.to_s).to include("Edinburgh West")
      end

      it "includes the access dates" do
        expect(mail.html_part.body.to_s).to include("1 May 2026")
        expect(mail.html_part.body.to_s).to include("1 August 2026")
      end

      it "addresses the tenant by first name" do
        expect(mail.html_part.body.to_s).to include("Hello Jane")
      end
    end

    context "multiple locks, shared PIN" do
      let(:grants) { [ make_grant(unit: "14", pin: "4821"), make_grant(unit: "22", pin: "4821") ] }
      let(:mail)   { described_class.access_granted(tenant, grants) }

      it "uses the singular PIN subject" do
        expect(mail.subject).to include("Your access PIN for 2 storage units")
      end

      it "includes the shared PIN once prominently" do
        expect(mail.html_part.body.to_s).to include("4821")
      end

      it "lists all units" do
        expect(mail.html_part.body.to_s).to include("Unit 14")
        expect(mail.html_part.body.to_s).to include("Unit 22")
      end

      it "reflects shared PIN in the text body" do
        expect(mail.text_part.body.to_s).to include("Your PIN works on all of them")
      end
    end

    context "multiple locks, different PINs" do
      let(:grants) { [ make_grant(unit: "14", pin: "4821"), make_grant(unit: "22", pin: "7392") ] }
      let(:mail)   { described_class.access_granted(tenant, grants) }

      it "uses the plural PINs subject" do
        expect(mail.subject).to include("Your access PINs for 2 storage units")
      end

      it "includes each PIN" do
        expect(mail.html_part.body.to_s).to include("4821")
        expect(mail.html_part.body.to_s).to include("7392")
      end

      it "includes each unit" do
        expect(mail.html_part.body.to_s).to include("Unit 14")
        expect(mail.html_part.body.to_s).to include("Unit 22")
      end

      it "reflects different PINs in the text body" do
        expect(mail.text_part.body.to_s).to include("each with its own PIN")
      end
    end
  end
end
