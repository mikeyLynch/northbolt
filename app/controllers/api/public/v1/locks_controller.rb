class Api::Public::V1::LocksController < Api::Public::V1::BaseController
  def index
    locks = @current_business.locks.includes(:location).to_a
    statuses = Lock.compute_tenancy_statuses(locks)

    if params[:available] == "true"
      locks = locks.select { |l| statuses[l.id] == "available" }
    end

    render json: locks.map { |l| lock_json(l, statuses[l.id]) }
  end

  def show
    lock = @current_business.locks.includes(:location).find(params[:id])
    render json: lock_json(lock, lock.tenancy_status)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Not found" }, status: :not_found
  end

  private

  def lock_json(lock, status)
    {
      id: lock.id,
      unit_identifier: lock.unit_identifier,
      device_uuid: lock.device_uuid,
      location: lock.location.name,
      last_seen_at: lock.last_seen_at,
      status: status
    }
  end
end
