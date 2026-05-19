class TenantMailer < ApplicationMailer
  def access_granted(tenant, grants)
    @tenant   = tenant
    @grants   = grants
    @business = grants.first.lock.location.business
    @same_pin = grants.map(&:pin_ciphertext).uniq.one?

    mail(to: @tenant.email, subject: subject_line)
  end

  private

  def subject_line
    if @grants.one?
      "Your access PIN for Unit #{@grants.first.lock.unit_identifier} — #{@business.name}"
    elsif @same_pin
      "Your access PIN for #{@grants.count} storage units — #{@business.name}"
    else
      "Your access PINs for #{@grants.count} storage units — #{@business.name}"
    end
  end
end
