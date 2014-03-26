class SessionsController < ApplicationController

  def new
    redirect_to '/auth/facebook'
  end

  def create
    auth = request.env["omniauth.auth"]
    user = User.where(:provider => auth['provider'],
                      :uid => auth['uid'].to_s).first || User.create_with_omniauth(auth)
    reset_session
    session[:user_id] = user.id
    if user.email.blank?
      redirect_to edit_user_path(user), alert:  "Please enter your email address."
    else
      redirect_to root_url, notice: 'Logged in!', anchor: 'logged_in'
    end
  end

  def destroy
    reset_session
    redirect_to root_url, notice:  'Logged out!', anchor: 'logged_out'
  end

  def failure
    redirect_to root_url, alert:  "Authentication error: #{params[:message].humanize}"
  end

end
