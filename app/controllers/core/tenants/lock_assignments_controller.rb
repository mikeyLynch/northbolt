class Core::Tenants::LockAssignmentsController < Core::BaseController
  before_action :set_tenant

  def new
    @available_locks = available_locks
  end

  def create
    shared_pin = params[:pin_mode] == "shared" ? rand(1000..9999).to_s : nil
    issued = []

    params.fetch(:lock_assignments, {}).each_value do |attrs|
      next if attrs[:lock_id].blank? || attrs[:ends_at].blank?

      lock = current_user.business.locks.includes(:location).find_by(id: attrs[:lock_id])
      next unless lock
      next if lock.access_grants.where(revoked_at: nil).exists?

      starts_at = attrs[:starts_at].present? ? Date.parse(attrs[:starts_at]) : Date.current
      ends_at   = Date.parse(attrs[:ends_at])

      AccessGrant.issue!(lock: lock, tenant: @tenant, starts_at: starts_at, ends_at: ends_at, pin: shared_pin)
      issued << { "unit_identifier" => lock.unit_identifier, "location_name" => lock.location.name }
    rescue ArgumentError, Date::Error, ActiveRecord::RecordInvalid
      next
    end

    count = issued.size
    redirect_to core_tenant_path(@tenant),
      notice: "Access granted — #{count == 1 ? "PIN" : "#{count} PINs"} sent to tenant."
  end

  private

  def set_tenant
    @tenant = current_user.business.tenants.find(params[:tenant_id])
  end

  def available_locks
    current_user.business.locks
      .joins(:location)
      .where.not(
        id: current_user.business.locks
              .joins(:access_grants)
              .where(access_grants: { revoked_at: nil })
              .select("locks.id")
      )
      .order(Arel.sql("locations.name, length(locks.unit_identifier), locks.unit_identifier"))
  end
end
