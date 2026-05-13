class Core::LocksController < Core::BaseController
  def index
    locks = current_user.business.locks.includes(:location)

    if params[:q].present?
      query = "%#{params[:q].strip.downcase}%"
      locks = locks.where(
        "LOWER(unit_identifier) LIKE :q OR LOWER(device_uuid) LIKE :q",
        q: query
      )
    end

    @locks = locks.order(Arel.sql("length(unit_identifier), unit_identifier")).page(params[:page]).per(25)
    @q = params[:q]
  end

  def show
    @lock = current_user.business.locks.find(params[:id])
  end
end
