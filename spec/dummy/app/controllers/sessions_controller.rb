class SessionsController < ApplicationController
  def new
    redirect_to "/" if user_signed_in?
  end

  def create
    email = params[:email].to_s.strip.downcase
    if email.blank?
      flash.now[:alert] = "Enter an email to sign in"
      return render :new, status: :unprocessable_entity
    end

    user = User.find_or_create_by!(email: email) do |u|
      u.name = email.split("@").first.titleize
    end
    session[:user_id] = user.id
    redirect_to "/"
  end

  def destroy
    session.delete(:user_id)
    redirect_to "/login"
  end
end
