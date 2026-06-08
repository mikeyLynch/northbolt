class Core::TenantsController < Core::BaseController
  TenantAuditEntry = Struct.new(:kind, :occurred_at, :lock, keyword_init: true)
  before_action :set_tenant, only: [ :show, :edit, :update, :destroy ]
  before_action -> { require_permission(:manage_tenants) }, only: [ :new, :create, :edit, :update, :destroy ]

  def index
    tenants = current_user.business.tenants

    if params[:q].present?
      query = "%#{params[:q].strip.downcase}%"
      tenants = tenants.where(
        "LOWER(first_name) LIKE :q OR LOWER(last_name) LIKE :q OR LOWER(email) LIKE :q OR LOWER(phone) LIKE :q",
        q: query
      )
    end

    @sort = params[:sort].presence_in(%w[name_asc name_desc newest oldest]) || "name_asc"

    tenants = case @sort
    when "name_desc" then tenants.order(last_name: :desc, first_name: :desc)
    when "newest"    then tenants.order(created_at: :desc)
    when "oldest"    then tenants.order(created_at: :asc)
    else                  tenants.order(last_name: :asc, first_name: :asc)
    end

    @tenants = tenants.page(params[:page]).per(25).includes(:access_grants)
    @q = params[:q]
  end

  def show
    @tab = params[:tab].presence_in(%w[overview locks audit]) || "overview"

    case @tab
    when "locks"
      grants = @tenant.access_grants.includes(lock: :location)
      grants = grants.where("starts_at >= ?", Date.parse(params[:from])) if params[:from].present?
      grants = grants.where("ends_at <= ?",   Date.parse(params[:to]).end_of_day) if params[:to].present?
      @access_grants = grants.order(Arel.sql("CASE WHEN revoked_at IS NULL AND ends_at > NOW() THEN 0 ELSE 1 END, created_at DESC"))
      @from = params[:from]
      @to   = params[:to]
    when "audit"
      entries = []
      @tenant.access_grants.includes(lock: :location).each do |grant|
        entries << TenantAuditEntry.new(kind: "grant_issued",  occurred_at: grant.created_at, lock: grant.lock)
        entries << TenantAuditEntry.new(kind: "grant_revoked", occurred_at: grant.revoked_at, lock: grant.lock) if grant.revoked_at
      end

      @audit_from = params[:audit_from]
      @audit_to   = params[:audit_to]

      if @audit_from.present?
        from = Date.parse(@audit_from).beginning_of_day
        entries.select! { |e| e.occurred_at >= from }
      end
      if @audit_to.present?
        to = Date.parse(@audit_to).end_of_day
        entries.select! { |e| e.occurred_at <= to }
      end

      sorted = entries.sort_by(&:occurred_at).reverse
      @audit_entries = Kaminari.paginate_array(sorted).page(params[:page]).per(50)
    when "overview"
      @active_grants = @tenant.access_grants
        .joins(lock: :location)
        .includes(lock: :location)
        .where(revoked_at: nil)
        .where("ends_at > ?", Time.current)
        .order(Arel.sql("locations.name, length(locks.unit_identifier), locks.unit_identifier"))
    end
  end

  def new
    @tenant = current_user.business.tenants.build
    @available_locks = available_locks
  end

  def create
    @tenant = current_user.business.tenants.build(tenant_params)

    if @tenant.save
      count = process_lock_assignments
      notice = count > 0 ? "Tenant created — #{count == 1 ? "PIN" : "#{count} PINs"} sent." : "Tenant created."
      redirect_to core_tenant_path(@tenant), notice: notice
    else
      @available_locks = available_locks
      flash.now[:alert] = "Please correct the errors below."
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @tenant.update(tenant_params)
      redirect_to core_tenant_path(@tenant)
    else
      flash.now[:alert] = "Please correct the errors below."
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @tenant.destroy
    redirect_to core_tenants_path
  end

  private

  def set_tenant
    @tenant = current_user.business.tenants.find(params[:id])
  end

  def tenant_params
    params.require(:tenant).permit(:first_name, :last_name, :email, :phone)
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

  def process_lock_assignments
    return 0 unless params[:lock_assignments].is_a?(ActionController::Parameters)

    shared_pin = params[:pin_mode] == "shared" ? rand(1000..9999).to_s : nil
    issued = 0

    params[:lock_assignments].each_value do |attrs|
      next if attrs[:lock_id].blank? || attrs[:ends_at].blank?

      lock = current_user.business.locks.includes(:location).find_by(id: attrs[:lock_id])
      next unless lock
      next if lock.access_grants.where(revoked_at: nil).exists?

      starts_at = attrs[:starts_at].present? ? Date.parse(attrs[:starts_at]) : Date.current
      ends_at   = Date.parse(attrs[:ends_at])

      AccessGrant.issue!(lock: lock, tenant: @tenant, starts_at: starts_at, ends_at: ends_at, pin: shared_pin)
      issued += 1
    rescue ArgumentError, Date::Error
      next
    end

    issued
  end
end
