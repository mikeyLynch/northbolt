require "rails_helper"

RSpec.describe "Core::Billing", type: :request do
  let(:user)     { create(:user) }
  let(:business) { user.business }

  before { sign_in user }

  describe "GET /billing" do
    it "is accessible" do
      get core_billing_path
      expect(response).to have_http_status(:ok)
    end

    it "does not show draft invoices" do
      create(:invoice, business: business, status: "draft")
      get core_billing_path
      expect(response.body).not_to include("NB-")
    end

    it "shows outstanding and paid invoices" do
      create(:invoice, business: business, status: "outstanding")
      create(:invoice, :paid, business: business)
      get core_billing_path
      expect(response.body).to include("Outstanding")
      expect(response.body).to include("Paid")
    end

    context "when not signed in" do
      before { sign_out user }

      it "redirects to sign in" do
        get core_billing_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /billing/invoices/:id/download" do
    let(:invoice) { create(:invoice, :outstanding, :with_line_items, business: business) }

    it "returns a PDF" do
      get core_billing_invoice_download_path(invoice)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/pdf")
    end

    it "cannot download an invoice belonging to another business" do
      other_invoice = create(:invoice, :outstanding, :with_line_items)
      get core_billing_invoice_download_path(other_invoice)
      expect(response).to have_http_status(:not_found)
    end
  end
end
