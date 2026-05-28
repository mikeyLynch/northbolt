class InvitationsController < ApplicationController
  layout "auth"

  def show
    @invitation = Invitation.pending.find_by(token: params[:token])
    redirect_to public_root_path, alert: "This invitation link is invalid or has already been used." unless @invitation
  end

  def accept
    @invitation = Invitation.pending.find_by(token: params[:token])
    unless @invitation
      return redirect_to public_root_path, alert: "This invitation link is invalid or has already been used."
    end

    user = @invitation.accept!(
      first_name: params[:first_name].to_s.strip,
      last_name:  params[:last_name].to_s.strip,
      password:   params[:password].to_s
    )
    sign_in user
    redirect_to core_dashboard_path, notice: "Welcome to #{@invitation.business.name}!"
  rescue ActiveRecord::RecordInvalid => e
    @invitation = Invitation.pending.find_by(token: params[:token])
    @errors = e.record.errors.full_messages
    render :show, status: :unprocessable_entity
  end
end
