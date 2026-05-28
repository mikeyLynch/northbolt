class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation  = invitation
    @business    = invitation.business
    @invited_by  = invitation.invited_by
    @accept_url  = accept_invitation_url(@invitation.token)

    mail to: invitation.email,
         subject: "#{@invited_by.first_name} invited you to join #{@business.name} on Northbolt"
  end
end
