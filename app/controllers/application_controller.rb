class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_filter :set_local_language
  before_filter :reject_honeypot
  before_filter :check_request_quota
  
  def set_local_language
    I18n.locale = 'kn'
  end

  def reject_honeypot
    if params[:website].present?
      head :no_content
    end
  end

  def check_request_quota
    session[:page_requests] ||= 0
    session[:page_requests] += 1
    if session[:page_requests] > 200
      session[:page_requests] = 0
      render plain: 'ದಯವಿಟ್ಟು ಸ್ವಲ್ಪ ಸಮಯದ ನಂತರ ಪ್ರಯತ್ನಿಸಿ', status: 429
    end
end
end
