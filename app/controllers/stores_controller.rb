class StoresController < ApplicationController
  def index
    @stores = Store.active.ordered
  end

  def suggestion
    name = params[:name]
    type = params[:type]
    sname = params.dig(:suggestion, :name)
    url = params.dig(:suggestion, :url)
    notes = params.dig(:suggestion, :notes)

    body = "ಹೊಸ ಸೂಚನೆ\n==========\n\n"
    body += "ಸೂಚಿಸಿದವರು: #{name}\n" if name.present?
    body += "ಪ್ರಕಾರ: #{type}\n"
    body += "ಹೆಸರು: #{sname}\n"
    body += "URL: #{url}\n" if url.present?
    body += "ಹೆಚ್ಚಿನ ಮಾಹಿತಿ: #{notes}\n" if notes.present?

    Rails.logger.info "[Store Suggestion] #{body}"

    flash[:notice] = "ಧನ್ಯವಾದಗಳು! ನಿಮ್ಮ ಸೂಚನೆಯನ್ನು ನಮುಗೆ ಪಡೆಯಲಾಗಿದೆ."
    redirect_to stores_path
  end
end