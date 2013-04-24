module SchedulerAdvisor
  class << self
    attr_accessor :advisor

    def uri
      @uri ||= Watchfire::Application.config.scheduler_uri
    end

    def method_missing(name, *args)
      advice name, *args
    end

    def advice(name, *args)
      return if @advisor.nil?

      args = args.map { |a| convert_argument(a) }
      begin
        @advisor.__send__(name, *args)
      rescue DRb::DRbConnError => e
        Rails.logger.warn "Error advising scheduler: #{e.message}"
      end
    end

  private

    def convert_argument(arg)
      if arg.respond_to?(:to_model)
        arg.to_model.to_param
      else
        arg
      end
    end
  end
end

