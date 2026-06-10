module Admin
  class TransliterationsController < BaseController
    def transliterate
      english_text = params[:text].to_s.strip
      
      if english_text.blank?
        render json: { error: 'No text provided' }, status: :bad_request
        return
      end
      
      # Call Aksharamukha API server-side to avoid CORS
      require 'net/http'
      require 'json'
      
      begin
        uri = URI("https://www.aksharamukha.appspot.com/api/transliterate")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.open_timeout = 5
        http.read_timeout = 5
        
        params_str = "?text=#{URI.encode_www_form_component(english_text)}&from=en_US&to=kn_KN"
        request = Net::HTTP::Get.new(uri.path + params_str)
        request['User-Agent'] = 'Rails App'
        
        response = http.request(request)
        
        if response.code == '200'
          data = JSON.parse(response.body)
          render json: data
        else
          render json: { error: 'API error', code: response.code }, status: :bad_gateway
        end
      rescue Timeout::Error, StandardError => e
        Rails.logger.error("Transliteration error: #{e.message}")
        render json: { error: e.message }, status: :bad_gateway
      end
    end
  end
end
