class Core::Tenants::AccessGrantsController < Core::BaseController
  before_action :set_tenant

  def new
    @available_locks = available_locks
  end

  def create
    lock = current_user.business.locks.find(params[:access_grant][:lock_id])
    ends_at = Date.parse(params[:access_grant][:ends_at]).end_of_day

    AccessGrant.issue!(lock: lock, tenant: @tenant, ends_at: ends_at)
    redirect_to core_tenant_path(@tenant, tab: "history"), notice: "Access granted — PIN sent to tenant."
  rescue ActiveRecord::RecordInvalid => e
    @available_locks = available_locks
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :new, status: :unprocessable_entity
  end

  private

  def set_tenant
    @tenant = current_user.business.tenants.find(params[:tenant_id])
  end

  def available_locks
    occupied_ids = AccessGrant.active.pluck(:lock_id)
    current_user.business.locks
                .includes(:location)
                .where.not(id: occupied_ids)
                .order(Arel.sql("length(unit_identifier), unit_identifier"))
  end
end
