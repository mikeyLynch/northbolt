class Api::Public::V1::BaseController < ActionController::API
  before_action :authenticate!

  private

  def authenticate!
    token = request.headers["Authorization"]&.delete_prefix("Bearer ")
    return unauthorized! unless token.present?

    @current_business = Business.find_by_api_key(token)
    unauthorized! unless @current_business
  end

  def unauthorized!
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
