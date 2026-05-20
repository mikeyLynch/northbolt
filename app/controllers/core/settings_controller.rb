class Core::SettingsController < Core::BaseController
  def index
    @tab      = params[:tab].presence_in(%w[general api_keys team locations integrations]) || "general"
    @business = current_user.business
  end

  def update_stora
    @business = current_user.business
    @business.generate_stora_webhook_token! unless @business.stora_webhook_token.present?

    secret = params[:stora_webhook_secret].presence
    @business.update!(stora_webhook_secret: secret) if secret

    redirect_to core_settings_path(tab: "integrations"), notice: "Stora integration updated."
  end
end
