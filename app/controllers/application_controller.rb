class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  layout :current_layout

  private

  def current_layout
    devise_controller? ? "auth" : "application"
  end

  private

  def after_sign_in_path_for(_resource)
    core_dashboard_path
  end

  def after_sign_out_path_for(_resource)
    public_root_path
  end
end
