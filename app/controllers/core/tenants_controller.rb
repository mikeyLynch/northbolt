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

    @sort = params[:sort].presence_in(%w[name_asc name_desc newest oldest]) || "name_asc"

    tenants = case @sort
              when "name_desc" then tenants.order(last_name: :desc, first_name: :desc)
              when "newest"    then tenants.order(created_at: :desc)
              when "oldest"    then tenants.order(created_at: :asc)
              else                  tenants.order(last_name: :asc, first_name: :asc)
              end

    @tenants = tenants.page(params[:page]).per(25).includes(:access_grants)
    @q = params[:q]
  end

  def show
    @tenant = current_user.business.tenants.find(params[:id])
    @tab = params[:tab].presence_in(%w[details history]) || "details"
    @access_grants = @tenant.access_grants.includes(:lock).order(created_at: :desc) if @tab == "history"
  end
end
