class TenantMailerPreview < ActionMailer::Preview
  def access_granted_single_lock
    tenant = preview_tenant
    grant  = preview_grant(tenant, unit: "14", pin: "4821")
    TenantMailer.access_granted(tenant, [ grant ])
  end

  def access_granted_multiple_locks_shared_pin
    tenant = preview_tenant
    grants = [
      preview_grant(tenant, unit: "14", pin: "4821"),
      preview_grant(tenant, unit: "22", pin: "4821"),
      preview_grant(tenant, unit: "31", pin: "4821")
    ]
    TenantMailer.access_granted(tenant, grants)
  end

  def access_granted_multiple_locks_different_pins
    tenant = preview_tenant
    grants = [
      preview_grant(tenant, unit: "14", pin: "4821"),
      preview_grant(tenant, unit: "22", pin: "7392")
    ]
    TenantMailer.access_granted(tenant, grants)
  end

  private

  def preview_tenant
    Tenant.first || Tenant.new(first_name: "Jane", last_name: "Smith", email: "jane@example.com")
  end

  def preview_grant(tenant, unit:, pin:)
    location = Location.first || Location.new(name: "Edinburgh West")
    business = location.business || Business.new(name: "Lynch Storage")
    location.instance_variable_set(:@business, business) unless location.persisted?

    lock = Lock.new(unit_identifier: unit, location: location)

    AccessGrant.new(
      lock:           lock,
      tenant:         tenant,
      pin_ciphertext: pin,
      starts_at:      Date.current.beginning_of_day,
      ends_at:        3.months.from_now.end_of_day
    )
  end
end
