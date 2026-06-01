class Core::Locks::AccessGrantsController < Core::BaseController
  before_action :set_lock
  before_action :ensure_no_active_grant
  before_action -> { require_permission(:grant_access) }

  def new
    @tenants = current_user.business.tenants.order(:last_name, :first_name)
  end

  def create
    starts_at = Date.parse(params[:access_grant][:starts_at]).beginning_of_day
    ends_at   = Date.parse(params[:access_grant][:ends_at]).end_of_day
    tenant    = find_or_build_tenant

    return render :new, status: :unprocessable_entity unless tenant.save

    grant, _pin = AccessGrant.issue!(lock: @lock, tenant: tenant, starts_at: starts_at, ends_at: ends_at)
    TenantMailer.access_granted(tenant, [ grant ]).deliver_later
    redirect_to core_lock_path(@lock), notice: "Access granted — PIN sent to tenant."
  rescue ActiveRecord::RecordInvalid => e
    @tenants = current_user.business.tenants.order(:last_name, :first_name)
    flash.now[:alert] = e.record.errors.full_messages.to_sentence
    render :new, status: :unprocessable_entity
  end

  private

  def set_lock
    @lock = current_user.business.locks.find(params[:lock_id])
  end

  def ensure_no_active_grant
    if @lock.current_grant.present?
      redirect_to core_lock_path(@lock), alert: "This lock already has an active tenant."
    end
  end

  def find_or_build_tenant
    if params[:access_grant][:tenant_mode] == "existing"
      current_user.business.tenants.find(params[:access_grant][:tenant_id])
    else
      current_user.business.tenants.find_or_initialize_by(
        email: params[:access_grant][:email].strip.downcase
      ) do |t|
        t.first_name = params[:access_grant][:first_name]
        t.last_name  = params[:access_grant][:last_name]
        t.phone      = params[:access_grant][:phone]
      end
    end
  end
end
