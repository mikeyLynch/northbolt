require "rails_helper"

RSpec.describe SendInvoiceJob, type: :job do
  let(:business) { create(:business) }
  let(:owner)    { create(:user, business: business, role: "owner") }
  let(:invoice)  { create(:invoice, :with_line_items, business: business, status: "outstanding") }

  before { owner }

  it "sends the invoice email" do
    expect { SendInvoiceJob.perform_now(invoice.id) }
      .to change { ActionMailer::Base.deliveries.count }.by(1)
  end

  it "addresses the email to the business owners" do
    SendInvoiceJob.perform_now(invoice.id)
    expect(ActionMailer::Base.deliveries.last.to).to include(owner.email)
  end

  it "does not send if already paid" do
    invoice.update!(status: "paid")
    expect { SendInvoiceJob.perform_now(invoice.id) }
      .not_to change { ActionMailer::Base.deliveries.count }
  end
end
