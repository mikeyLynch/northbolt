class Core::ActivityController < Core::BaseController
  before_action -> { require_permission(:view_activity) }

  def index
    @period = params[:period]
    @from   = params[:from]
    @to     = params[:to]

    case @period
    when "today"
      @from = Date.current.to_s
      @to   = Date.current.to_s
    when "yesterday"
      @from = Date.yesterday.to_s
      @to   = Date.yesterday.to_s
    when "month"
      @from = Date.current.beginning_of_month.to_s
      @to   = Date.current.to_s
    end

    events = AccessEvent
      .joins(lock: :location)
      .where(locations: { business_id: current_user.business_id })
      .includes(lock: :location)
      .order(occurred_at: :desc)

    events = events.where("occurred_at >= ?", Date.parse(@from).beginning_of_day) if @from.present?
    events = events.where("occurred_at <= ?", Date.parse(@to).end_of_day)         if @to.present?

    @events = events.page(params[:page]).per(50)
  end
end
