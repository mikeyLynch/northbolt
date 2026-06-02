class Core::SupportController < Core::BaseController
  def create
    subject = params[:subject].to_s.strip
    message = params[:message].to_s.strip

    if subject.present? && message.present?
      SupportMailer.ticket(user: current_user, subject: subject, message: message).deliver_later
      flash[:support_notice] = "Message sent — we'll be in touch shortly."
    else
      flash[:support_alert] = "Please fill in both subject and message."
    end

    redirect_back fallback_location: core_dashboard_path
  end
end
