class Api::Public::V1::LocksController < Api::Public::V1::BaseController
  def index
    locks = @current_business.locks
    locks = locks.select { |l| l.tenancy_status == "available" } if params[:available] == "true"

    render json: locks.map { |l| lock_json(l) }
  end

  def show
    lock = @current_business.locks.find(params[:id])
    render json: lock_json(lock)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

  private

  def lock_json(lock)
    {
      id: lock.id,
      unit_identifier: lock.unit_identifier,
      device_uuid: lock.device_uuid,
      location: lock.location.name,
      last_seen_at: lock.last_seen_at,
      status: lock.tenancy_status
    }
  end
end
