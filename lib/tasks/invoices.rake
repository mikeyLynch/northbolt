# Invoice management rake tasks
#
# All invoices are created in draft status and must be explicitly sent.
# Use invoices:list to find invoice IDs before sending, marking paid, or refunding.
#
# Typical hardware workflow:
#   1. bin/rails "invoices:create_hardware[1,10,deposit]"          # 50% deposit invoice
#   2. bin/rails "invoices:send[1]"                                 # email it to the business owner
#   3. (payment received via BACS)
#   4. bin/rails "invoices:mark_paid[1]"
#   5. (hardware ships)
#   6. bin/rails "invoices:create_delivery_with_service[1,10]"     # 50% delivery + first year service fee
#   7. bin/rails "invoices:send[2]"
#   8. bin/rails "invoices:mark_paid[2]"
#
# Typical service workflow:
#   1. bin/rails "invoices:create_service[1]"               # locks count pulled automatically
#   2. bin/rails "invoices:send[3]"
#   3. bin/rails "invoices:mark_paid[3]"
#   Repeat annually.
#
# Discounts (optional on create tasks):
#   discount_type  — "fixed" or "percentage"
#   discount_value — pence for fixed (e.g. 5000 = £50), or a number for percentage (e.g. 10 = 10%)
#   Examples:
#     bin/rails "invoices:create_service[1,percentage,10]"   # 10% off
#     bin/rails "invoices:create_hardware[1,10,full,fixed,5000]"  # £50 off
#
# Refunds:
#   amount_pence — amount in pence (e.g. 2990 = £29.90)
#   reason       — free text, shown on the billing dashboard
#   Example:
#     bin/rails "invoices:refund[1,29900,Customer requested refund for one lock]"

namespace :invoices do
  desc "Create a hardware invoice. Args: business_id, lock_count, installment (deposit|delivery|full), [discount_type], [discount_value]"
  task :create_hardware, [ :business_id, :lock_count, :installment, :discount_type, :discount_value ] => :environment do |_, args|
    business    = Business.find(args[:business_id])
    lock_count  = args[:lock_count].to_i
    installment = args[:installment].presence_in(%w[deposit delivery full]) || abort("installment must be deposit, delivery or full")

    invoice = Invoice.create_hardware!(
      business:       business,
      lock_count:     lock_count,
      installment:    installment,
      discount_type:  args[:discount_type].presence,
      discount_value: args[:discount_value].presence
    )

    puts "Created invoice #{invoice.number} (#{invoice.formatted_total} inc. VAT) — status: draft"
  end

  # Used for the second hardware invoice — combines the 50% delivery balance with the first
  # year's service fee into a single payment. Run this after hardware ships and the deposit
  # has been paid. The service period (start → start + 1 year) is stamped on the invoice
  # and drives the renewal date shown on the business's billing dashboard.
  #
  # Example:
  #   bin/rails "invoices:create_delivery_with_service[1,10]"
  #   bin/rails "invoices:create_delivery_with_service[1,10,percentage,10]"  # with 10% discount
  desc "Create a combined delivery + first year service invoice. Args: business_id, lock_count, [discount_type], [discount_value]"
  task :create_delivery_with_service, [ :business_id, :lock_count, :discount_type, :discount_value ] => :environment do |_, args|
    business   = Business.find(args[:business_id])
    lock_count = args[:lock_count].to_i
    abort("lock_count must be greater than 0") unless lock_count > 0

    invoice = Invoice.create_delivery_and_service!(
      business:       business,
      lock_count:     lock_count,
      discount_type:  args[:discount_type].presence,
      discount_value: args[:discount_value].presence
    )

    puts "Created invoice #{invoice.number} (#{invoice.formatted_total} inc. VAT) — hardware delivery + service fee for #{lock_count} locks — status: draft"
  end

  desc "Create a service invoice. Args: business_id, [discount_type], [discount_value]"
  task :create_service, [ :business_id, :discount_type, :discount_value ] => :environment do |_, args|
    business = Business.find(args[:business_id])

    invoice = Invoice.create_service!(
      business:       business,
      discount_type:  args[:discount_type].presence,
      discount_value: args[:discount_value].presence
    )

    puts "Created invoice #{invoice.number} (#{invoice.formatted_total} inc. VAT) for #{business.locks.count} locks — status: draft"
  end

  desc "Send an invoice by ID (enqueues background job, emails business owners)"
  task :send, [ :invoice_id ] => :environment do |_, args|
    invoice = Invoice.find(args[:invoice_id])

    if invoice.status == "outstanding" || invoice.status == "paid"
      puts "ERROR: Invoice #{invoice.number} is already #{invoice.status}. Nothing sent."
      exit 1
    end

    invoice.update!(status: :outstanding, issued_at: Date.current, due_at: Date.current + 30.days)
    SendInvoiceJob.perform_now(invoice.id)
    puts "Sent invoice #{invoice.number} → #{invoice.business.users.where(role: 'owner').pluck(:email).join(', ')}"
  end

  desc "Mark an invoice as paid. Args: invoice_id"
  task :mark_paid, [ :invoice_id ] => :environment do |_, args|
    invoice = Invoice.find(args[:invoice_id])
    invoice.update!(status: :paid, paid_at: Time.current)
    puts "Invoice #{invoice.number} marked as paid."
  end

  desc "Issue a refund against an invoice. Args: invoice_id, amount_pence, reason"
  task :refund, [ :invoice_id, :amount_pence, :reason ] => :environment do |_, args|
    invoice      = Invoice.find(args[:invoice_id])
    amount_pence = args[:amount_pence].to_i
    reason       = args[:reason].to_s.strip

    abort("amount_pence must be greater than 0") unless amount_pence > 0
    abort("reason is required") if reason.blank?
    abort("Refund amount exceeds invoice total") if amount_pence > invoice.total_pence

    refund = invoice.refunds.create!(amount_pence: amount_pence, reason: reason, issued_at: Time.current)
    puts "Refund of #{refund.formatted_amount} issued against invoice #{invoice.number}. Reason: #{reason}"
  end

  desc "List all invoices for a business. Args: business_id"
  task :list, [ :business_id ] => :environment do |_, args|
    invoices = Business.find(args[:business_id]).invoices.recent

    if invoices.empty?
      puts "No invoices found."
    else
      invoices.each do |inv|
        puts "#{inv.number} | #{inv.category} #{inv.installment} | #{inv.formatted_total} | #{inv.status} | #{inv.issued_at}"
      end
    end
  end
end
