require 'json'

module SchedulerAdvisor
  class << self
    def port
      @port ||= Watchfire::Application.config.scheduler_port.to_i
    end

    def open
      begin
        client = EM.connect '127.0.0.1', port, self
        yield client
      ensure
        client.close_connection_after_writing if client
      end
      client
    end

    def method_missing(name, *args)
      advice name, *args
    end

    def advice(*args)
      open do |client|
        client.advice *args
      end
    end
  end

  def convert_argument(arg)
    if arg.respond_to?(:to_model)
      arg.to_model.to_param
    else
      arg
    end
  end

  def advice(name, *args)
    data = [name] + args.map { |a| convert_argument(a) }
    send_data data.to_json + "\n"
  end
end

