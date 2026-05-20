class Webhooks::StoraController < ActionController::API
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: -> { head :bad_request }

  HANDLED_EVENTS = %w[
    subscription.started
    subscription.cancelled
    subscription.ended
    invoice.marked_uncollectible
  ].freeze

  def create
    @business = Business.find_by(stora_webhook_token: params[:token])
    return head :not_found unless @business

    payload = request.raw_post
    unless @business.verify_stora_signature(payload, request.headers["X-Stora-Signature"])
      return head :unauthorized
    end

    data = JSON.parse(payload)
    event_type = data.dig("event", "type")

    unless HANDLED_EVENTS.include?(event_type)
      return head :ok
    end

    handle_event(event_type, data)
    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  private

  def handle_event(event_type, data)
    case event_type
    when "subscription.started"
      handle_subscription_started(data)
    when "subscription.cancelled", "subscription.ended"
      handle_subscription_ended(data)
    when "invoice.marked_uncollectible"
      handle_invoice_uncollectible(data)
    end
  end

  def handle_subscription_started(data)
    tenant     = find_or_build_tenant(data)
    unit_id    = data.dig("subscription", "unit_id")
    starts_at  = parse_time(data.dig("subscription", "starts_at"))
    ends_at    = parse_time(data.dig("subscription", "ends_at"))

    lock = @business.locks.joins(:location).find_by(unit_identifier: unit_id)
    return unless lock && tenant && starts_at && ends_at

    tenant.save! unless tenant.persisted?

    grant, = AccessGrant.issue!(
      lock:      lock,
      tenant:    tenant,
      starts_at: starts_at,
      ends_at:   ends_at
    )

    TenantMailer.access_granted(tenant, [ grant ]).deliver_later
  end

  def handle_subscription_ended(data)
    unit_id   = data.dig("subscription", "unit_id")
    tenant_id = data.dig("subscription", "tenant_id")

    lock = @business.locks.joins(:location).find_by(unit_identifier: unit_id)
    return unless lock

    active_grants = lock.access_grants
                        .where(revoked_at: nil)
                        .joins(:tenant)
                        .where(tenants: { external_id: tenant_id })

    active_grants.update_all(revoked_at: Time.current)
  end

  def handle_invoice_uncollectible(data)
    tenant_id = data.dig("invoice", "tenant_id")

    tenant = @business.tenants.find_by(external_id: tenant_id)
    return unless tenant

    tenant.access_grants
          .where(revoked_at: nil)
          .update_all(revoked_at: Time.current)
  end

  def find_or_build_tenant(data)
    tenant_data = data["tenant"] || {}
    external_id = data.dig("subscription", "tenant_id")
    return nil unless external_id

    tenant = @business.tenants.find_or_initialize_by(external_id: external_id)
    tenant.first_name = tenant_data["first_name"].presence || tenant.first_name
    tenant.last_name  = tenant_data["last_name"].presence  || tenant.last_name
    tenant.email      = tenant_data["email"].presence      || tenant.email
    tenant
  end

  def parse_time(value)
    return nil unless value
    Time.zone.parse(value)
  rescue ArgumentError
    nil
  end
end
