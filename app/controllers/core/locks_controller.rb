class Core::LocksController < Core::BaseController
  AuditEntry = Struct.new(:kind, :occurred_at, :tenant, keyword_init: true)
  def index
    @locations = current_user.business.locations.order(:name)
    locks = current_user.business.locks.includes(:location)

    if params[:location_id].present?
      @location = @locations.find_by(id: params[:location_id])
      locks = locks.where(location: @location) if @location
    end

    if params[:q].present?
      query = "%#{params[:q].strip.downcase}%"
      locks = locks.where("LOWER(unit_identifier) LIKE :q", q: query)
    end

    @sort = params[:sort].presence_in(%w[unit_asc unit_desc last_accessed_asc last_accessed_desc]) || "unit_asc"

    locks = case @sort
            when "unit_desc"                               then locks.order(Arel.sql("length(unit_identifier) DESC, unit_identifier DESC"))
            when "last_accessed_asc", "last_accessed_desc" then locks.order(Arel.sql("length(unit_identifier), unit_identifier"))
            else                                                locks.order(Arel.sql("length(unit_identifier), unit_identifier"))
    end

    @locks = locks.page(params[:page]).per(25)
    @q = params[:q]
    @tenancy_statuses = compute_tenancy_statuses(@locks)
  end

  def show
    @lock = current_user.business.locks.includes(:location, :current_tenant).find(params[:id])
    @tenancy_status = @lock.tenancy_status
    @tab = params[:tab].presence_in(%w[overview history audit]) || "overview"

    case @tab
    when "overview"
      @current_grant = @lock.access_grants.includes(:tenant)
                            .where(revoked_at: nil)
                            .where("ends_at > ?", Time.current)
                            .order(:starts_at)
                            .first
    when "history"
      grants = @lock.access_grants.includes(:tenant).order(created_at: :desc)
      grants = grants.where("starts_at >= ?", Date.parse(params[:from])) if params[:from].present?
      grants = grants.where("ends_at <= ?",   Date.parse(params[:to]).end_of_day) if params[:to].present?
      @access_grants = grants
      @from = params[:from]
      @to   = params[:to]
    when "audit"
      entries = []

      @lock.access_grants.includes(:tenant).each do |grant|
        entries << AuditEntry.new(kind: "grant_issued",  occurred_at: grant.created_at, tenant: grant.tenant)
        entries << AuditEntry.new(kind: "grant_revoked", occurred_at: grant.revoked_at, tenant: grant.tenant) if grant.revoked_at
      end

      @lock.access_events.each do |event|
        entries << AuditEntry.new(kind: event.event_type, occurred_at: event.occurred_at, tenant: nil)
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
    end
  end

  private

  def compute_tenancy_statuses(locks)
    Lock.compute_tenancy_statuses(locks)
  end
end
