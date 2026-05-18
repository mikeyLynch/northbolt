class Api::Public::V1::TenantsController < Api::Public::V1::BaseController
  def index
    tenants = @current_business.tenants.order(:last_name, :first_name)
    render json: tenants.map { |t| tenant_json(t) }
  end

  def create
    tenant = @current_business.tenants.new(tenant_params)

    if tenant.save
      render json: tenant_json(tenant), status: :created
    else
      render json: { errors: tenant.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def tenant_params
    params.require(:tenant).permit(:first_name, :last_name, :email, :phone)
  end

  def tenant_json(tenant)
    {
      id: tenant.id,
      first_name: tenant.first_name,
      last_name: tenant.last_name,
      email: tenant.email,
      phone: tenant.phone,
      created_at: tenant.created_at
    }
  end
end
