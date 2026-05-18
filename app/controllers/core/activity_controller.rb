class Core::ActivityController < Core::BaseController
  def index
    @events = AccessEvent
      .joins(lock: :location)
      .where(locations: { business_id: current_user.business_id })
      .includes(lock: :location)
      .order(occurred_at: :desc)
      .page(params[:page])
      .per(50)
  end
end
