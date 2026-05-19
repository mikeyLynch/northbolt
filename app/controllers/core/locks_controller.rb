class Core::LocksController < Core::BaseController
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
      @access_grants = @lock.access_grants.includes(:tenant).order(created_at: :desc)
    when "audit"
      @access_events = @lock.access_events.recent.page(params[:page]).per(50)
    end
  end

  private

  def compute_tenancy_statuses(locks)
    Lock.compute_tenancy_statuses(locks)
  end
end
