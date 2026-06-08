class Core::AccountController < Core::BaseController
  def show
  end

  def update_profile
    if current_user.update(first_name: params[:first_name].to_s.strip,
                           last_name:  params[:last_name].to_s.strip,
                           email:      params[:email].to_s.strip.downcase)
      redirect_to core_account_path, notice: "Profile updated."
    else
      flash.now[:alert] = "Please correct the errors below."
      render :show, status: :unprocessable_content
    end
  end

  def update_password
    unless current_user.valid_password?(params[:current_password])
      flash.now[:password_alert] = "Current password is incorrect."
      return render :show, status: :unprocessable_content
    end

    if params[:password] != params[:password_confirmation]
      flash.now[:password_alert] = "New passwords don't match."
      return render :show, status: :unprocessable_content
    end

    current_user.update!(password: params[:password])
    bypass_sign_in(current_user)
    redirect_to core_account_path, notice: "Password updated."
  end
end
