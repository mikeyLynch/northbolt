class Core::SettingsController < Core::BaseController
  def index
    @tab      = params[:tab].presence_in(%w[general api_keys team permissions locations integrations]) || "general"
    @business = current_user.business
    @api_keys    = @business.api_keys.recent                              if @tab == "api_keys"
    @members     = @business.users.order(:first_name, :last_name)         if @tab == "team"
    @invitations = @business.invitations.pending.order(created_at: :desc) if @tab == "team"
    @locations   = @business.locations.order(:name)                       if @tab == "locations"
  end

  def update_general
    return require_permission(:manage_settings) unless can?(:manage_settings)
    current_user.business.update!(name: params[:name].to_s.strip.presence || current_user.business.name)
    redirect_to core_settings_path(tab: "general"), notice: "Settings saved."
  end

  def update_permissions
    return redirect_to(core_dashboard_path, alert: "Only owners can manage permissions.") unless current_user.owner?
    matrix = {}
    %w[high medium low].each do |role|
      matrix[role] = Array(params.dig(:permissions, role)).select { |p| Business::PERMISSIONS.include?(p) }
    end
    current_user.business.update!(permission_matrix: matrix)
    redirect_to core_settings_path(tab: "permissions"), notice: "Permissions saved."
  end

  def create_api_key
    return require_permission(:manage_api_keys) unless can?(:manage_api_keys)
    name = params[:api_key_name].presence
    return redirect_to(core_settings_path(tab: "api_keys"), alert: "Name can't be blank.") unless name

    key, token = ApiKey.generate(business: current_user.business, name: name)
    redirect_to core_settings_path(tab: "api_keys"), flash: { new_token: token, new_key_id: key.id }
  end

  def revoke_api_key
    return require_permission(:manage_api_keys) unless can?(:manage_api_keys)
    key = current_user.business.api_keys.find(params[:id])
    key.revoke!
    redirect_to core_settings_path(tab: "api_keys"), notice: "API key revoked."
  end

  def create_invitation
    return require_permission(:manage_team) unless can?(:manage_team)
    email = params[:email].to_s.strip.downcase
    role  = params[:role].presence_in(%w[high medium low]) || "medium"

    if User.exists?(email: email)
      return redirect_to core_settings_path(tab: "team"), alert: "#{email} already has a Northbolt account."
    end

    if current_user.business.invitations.pending.exists?(email: email)
      return redirect_to core_settings_path(tab: "team"), alert: "An invitation has already been sent to #{email}."
    end

    invitation = current_user.business.invitations.create!(email: email, invited_by: current_user, role: role)
    InvitationMailer.invite(invitation).deliver_later
    redirect_to core_settings_path(tab: "team"), notice: "Invitation sent to #{email}."
  end

  def resend_invitation
    invitation = current_user.business.invitations.pending.find(params[:id])
    invitation.regenerate_token!
    InvitationMailer.invite(invitation).deliver_later
    redirect_to core_settings_path(tab: "team"), notice: "Invitation resent to #{invitation.email}."
  end

  def cancel_invitation
    invitation = current_user.business.invitations.find(params[:id])
    invitation.destroy!
    redirect_to core_settings_path(tab: "team"), notice: "Invitation cancelled."
  end

  def remove_member
    return require_permission(:manage_team) unless can?(:manage_team)
    member = current_user.business.users.find(params[:id])
    if member == current_user
      return redirect_to core_settings_path(tab: "team"), alert: "You can't remove yourself."
    end
    if member.owner? && !current_user.owner?
      return redirect_to core_settings_path(tab: "team"), alert: "Only owners can remove other owners."
    end
    member.destroy!
    redirect_to core_settings_path(tab: "team"), notice: "#{member.first_name} #{member.last_name} removed."
  end

  def update_stora
    @business = current_user.business
    @business.generate_stora_webhook_token! unless @business.stora_webhook_token.present?

    secret = params[:stora_webhook_secret].presence
    @business.update!(stora_webhook_secret: secret) if secret

    redirect_to core_settings_path(tab: "integrations"), notice: "Stora integration updated."
  end
end
