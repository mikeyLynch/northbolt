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
            when "unit_desc"                            then locks.order(Arel.sql("length(unit_identifier) DESC, unit_identifier DESC"))
            when "last_accessed_asc", "last_accessed_desc" then locks.order(Arel.sql("length(unit_identifier), unit_identifier"))
            else                                             locks.order(Arel.sql("length(unit_identifier), unit_identifier"))
            end

    @locks = locks.page(params[:page]).per(25)
    @q = params[:q]
  end

  def show
    @lock = current_user.business.locks.find(params[:id])
  end
end
