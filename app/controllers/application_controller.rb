class ApplicationController < ActionController::API
  include ActionController::Cookies  # enable cookie
  # redirect unauthorized user
  before_action :authenticate_user!
  private def authenticate_user!
    unless session[:zoom_access_token]
      redirect_to zoom_oauth_path
    end
  end
end
