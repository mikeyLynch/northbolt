class Core::TenantsController < Core::BaseController
  def index
    tenants = current_user.business.tenants

    if params[:q].present?
      query = "%#{params[:q].strip.downcase}%"
      tenants = tenants.where(
        "LOWER(first_name) LIKE :q OR LOWER(last_name) LIKE :q OR LOWER(email) LIKE :q OR LOWER(phone) LIKE :q",
        q: query
      )
    end

    @tenants = tenants.order(:last_name, :first_name).page(params[:page]).per(25)
    @q = params[:q]
  end

  def show
    @tenant = current_user.business.tenants.find(params[:id])
    @tab = params[:tab].presence_in(%w[details history]) || "details"
    @access_grants = @tenant.access_grants.includes(:lock).order(created_at: :desc) if @tab == "history"
  end
end
