class Core::BillingController < Core::BaseController
  def index
    @business = current_user.business
    @invoices = @business.invoices.where.not(status: "draft").recent.includes(:line_items, :refunds)

    @active_service = @business.invoices
                               .where(status: %w[outstanding paid])
                               .where.not(service_period_end: nil)
                               .order(service_period_end: :desc)
                               .first
  end

  def download_invoice
    invoice = current_user.business.invoices.find(params[:id])
    pdf     = InvoicePdfService.new(invoice).render

    send_data pdf,
              filename:    "#{invoice.number}.pdf",
              type:        "application/pdf",
              disposition: "attachment"
  end
end
