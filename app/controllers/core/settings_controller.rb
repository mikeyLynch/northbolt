class Core::SettingsController < Core::BaseController
  def index
    @tab = params[:tab].presence_in(%w[general api_keys team]) || "general"
  end
end
