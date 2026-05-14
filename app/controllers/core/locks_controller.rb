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
    @access_grants = @lock.access_grants.includes(:tenant).order(created_at: :desc)
    @tenancy_status = @lock.tenancy_status
  end

  private

  def compute_tenancy_statuses(locks)
    now = Time.current
    lock_ids = locks.map(&:id)
    statuses = lock_ids.index_with { "available" }

    AccessGrant
      .where(lock_id: lock_ids, revoked_at: nil)
      .where("ends_at > ?", now)
      .where("starts_at <= ?", 1.week.from_now)
      .select(:lock_id, :starts_at, :ends_at)
      .each do |grant|
        current = statuses[grant.lock_id]
        if grant.starts_at <= now
          if grant.ends_at <= 3.days.from_now
            statuses[grant.lock_id] = "available_soon"
          elsif current != "available_soon"
            statuses[grant.lock_id] = "unavailable"
          end
        elsif current == "available"
          statuses[grant.lock_id] = "unavailable_soon"
        end
      end

    statuses
  end
end
