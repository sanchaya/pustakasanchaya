# Monkey patch for BigDecimal.new compatibility with Ruby 2.4+
# Rails 4.2.11.1 tries to call BigDecimal.new which was removed in Ruby 2.4
class BigDecimal
  class << self
    alias_method :_original_new, :new
    def new(*args)
      if args.empty?
        BigDecimal(0)
      else
        BigDecimal(*args)
      end
    end
  end
end
