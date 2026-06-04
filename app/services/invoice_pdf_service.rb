class InvoicePdfService
  def initialize(invoice)
    @invoice = invoice
    @business = invoice.business
  end

  def render
    Receipts::Invoice.new(
      company: {
        name:  Invoice::COMPANY_NAME,
        email: Invoice::COMPANY_EMAIL,
        logo:  nil
      },
      details: [
        [ "Invoice number", @invoice.number ],
        [ "Date",           @invoice.issued_at.strftime("%-d %B %Y") ],
        [ "Due",            @invoice.due_at.strftime("%-d %B %Y") ],
        [ "Status",         @invoice.status.capitalize ],
        [ "",               "" ],
        [ "From",           Invoice::COMPANY_NAME ],
        [ "",               Invoice::COMPANY_ADDRESS ],
        [ "",               Invoice::COMPANY_EMAIL ],
        [ "",               "VAT No: #{Invoice::COMPANY_VAT}" ]
      ],
      recipient: [
        @business.billing_legal_name,
        @business.billing_address_line_1,
        @business.billing_address_line_2,
        [@business.billing_city, @business.billing_postcode].compact.join(", "),
        ("VAT No: #{@business.vat_number}" if @business.vat_registered?)
      ].compact.reject(&:blank?),
      line_items: line_items,
      footer:     notes_text
    ).render
  end

  private

  def line_items
    rows = [["Description", "Qty", "Unit price", "Amount"]]

    @invoice.line_items.each do |item|
      rows << [
        item.description,
        item.quantity.to_i.to_s,
        item.formatted_unit_price,
        item.formatted_total
      ]
    end

    rows << ["", "", "Subtotal", @invoice.formatted_subtotal]

    if @invoice.discount_amount_pence > 0
      label = @invoice.discount_type == "percentage" ? "Discount (#{@invoice.discount_value.to_i}%)" : "Discount"
      rows << ["", "", label, "-#{@invoice.formatted_discount}"]
    end

    rows << ["", "", "VAT (#{(@invoice.vat_rate * 100).to_i}%)", @invoice.formatted_vat]
    rows << ["", "", "Total", @invoice.formatted_total]

    rows
  end

  def notes_text
    parts = []
    parts << "Payment by BACS: #{Invoice::COMPANY_BACS}"
    parts << "Please reference #{@invoice.number} with your payment."

    if @invoice.service_period_start && @invoice.service_period_end
      parts << "Service period: #{@invoice.service_period_start.strftime('%-d %b %Y')} – #{@invoice.service_period_end.strftime('%-d %b %Y')}"
    end

    parts << @invoice.notes if @invoice.notes.present?

    parts << "#{Invoice::COMPANY_NAME} · Company No: #{Invoice::COMPANY_NUMBER} · VAT No: #{Invoice::COMPANY_VAT}"

    parts.join("\n")
  end
end
