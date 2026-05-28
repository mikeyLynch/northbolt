class Core::SettingsController < Core::BaseController
  def index
    @tab      = params[:tab].presence_in(%w[general api_keys team locations integrations]) || "general"
    @business = current_user.business
    @api_keys = @business.api_keys.recent if @tab == "api_keys"
  end

  def create_api_key
    name = params[:api_key_name].presence
    return redirect_to(core_settings_path(tab: "api_keys"), alert: "Name can't be blank.") unless name

    key, token = ApiKey.generate(business: current_user.business, name: name)
    redirect_to core_settings_path(tab: "api_keys"), flash: { new_token: token, new_key_id: key.id }
  end

  def revoke_api_key
    key = current_user.business.api_keys.find(params[:id])
    key.revoke!
    redirect_to core_settings_path(tab: "api_keys"), notice: "API key revoked."
  end

  def update_stora
    @business = current_user.business
    @business.generate_stora_webhook_token! unless @business.stora_webhook_token.present?

    secret = params[:stora_webhook_secret].presence
    @business.update!(stora_webhook_secret: secret) if secret

    redirect_to core_settings_path(tab: "integrations"), notice: "Stora integration updated."
  end
end
