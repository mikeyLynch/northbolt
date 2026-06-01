module Authorizable
  extend ActiveSupport::Concern

  included do
    helper_method :can?
  end

  def can?(permission)
    return true if current_user.owner?
    current_user.business.role_can?(current_user.role, permission)
  end

  def require_permission(permission)
    unless can?(permission)
      redirect_to core_dashboard_path, alert: "You don't have permission to do that."
    end
  end
end
