class RateLimiter
  MAX_REQUESTS = 120
  TIME_WINDOW = 60
  CLEAN_INTERVAL = 300

  def initialize(app)
    @app = app
    @requests = {}
    @mutex = Mutex.new
  end

  def call(env)
    ip = extract_ip(env)
    now = Time.now.to_i

    @mutex.synchronize do
      clean_old(now)
      @requests[ip] ||= []
      @requests[ip] << now

      if @requests[ip].size > MAX_REQUESTS
        return [429, { 'Content-Type' => 'text/plain' }, ['ದಯವಿಟ್ಟು ಸ್ವಲ್ಪ ಸಮಯದ ನಂತರ ಪ್ರಯತ್ನಿಸಿ (rate limit exceeded)']]
      end
    end

    @app.call(env)
  end

  private

  def extract_ip(env)
    env['HTTP_X_FORWARDED_FOR']&.split(',')&.first&.strip || env['REMOTE_ADDR'] || 'unknown'
  end

  def clean_old(now)
    cutoff = now - TIME_WINDOW
    @requests.each_key { |ip| @requests[ip].reject! { |t| t < cutoff } }
    @requests.reject! { |_ip, times| times.empty? }
  end
end
