class InvoiceMailer < ApplicationMailer
  def invoice(invoice)
    @invoice  = invoice
    @business = invoice.business

    mail to:      @business.users.where(role: "owner").pluck(:email),
         subject: "Invoice #{invoice.number} from Northbolt"
  end
end
