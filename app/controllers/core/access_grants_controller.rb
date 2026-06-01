class Core::AccessGrantsController < Core::BaseController
  before_action :set_grant
  before_action -> { require_permission(:grant_access) }, only: [ :edit, :update ]
  before_action -> { require_permission(:revoke_access) }, only: [ :revoke ]

  def edit
    @return_to = params[:return_to]
  end

  def update
    starts_at = Date.parse(params.dig(:access_grant, :starts_at)).beginning_of_day
    ends_at   = Date.parse(params.dig(:access_grant, :ends_at)).end_of_day

    if @grant.update(starts_at: starts_at, ends_at: ends_at)
      redirect_to return_to_path
    else
      @return_to = params[:return_to]
      render :edit, status: :unprocessable_entity
    end
  rescue ArgumentError, Date::Error
    @return_to = params[:return_to]
    render :edit, status: :unprocessable_entity
  end

  def revoke
    @grant.revoke!
    redirect_to return_to_path
  end

  private

  def set_grant
    @grant = AccessGrant.joins(lock: :location)
                        .where(locations: { business_id: current_user.business.id })
                        .find(params[:id])
  end

  def return_to_path
    path = params[:return_to]
    path.present? && path.start_with?("/") ? path : core_lock_path(@grant.lock)
  end
end
