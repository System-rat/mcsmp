# frozen_string_literal: true

require 'singleton'

module MCSMP
  # The main instance of the connector
  class Connector
    include Singleton

    attr_accessor :config
    attr_reader :server_instances, :server_runners

    def initialize
      @config = MCSMP::ConnectorConfig.new
      @server_instances = []
      @server_runners = []
    end

    def path
      @config.path
    end

    def path=(p)
      @config.path = p
    end

    def load_connector(autostart: true, with_pry: false)
      @server_instances = MCSMP::Util.get_instances(path)
      @server_runners = MCSMP::Util.get_runners(@server_instances)
      self.autostart if autostart
      start_connector(!with_pry)
      return unless with_pry

      require 'pry'

      pry quiet: true, prompt: Pry::Prompt.new(
        'MCSMP',
        'MCSMP CLI prompt',
        [
          proc { 'Connector >> ' },
          proc { ' * ' }
        ]
      )
      stop
    rescue LoadError
      warn 'Install the pry gem for this feature.'
    end

    def stop
      MCSMP::HTTPConnector.stop!
      @server_runners.each(&:stop)
    end

    private

    def start_connector(blocking = false)
      MCSMP::HTTPConnector.set :port, @config.port
      MCSMP::HTTPConnector.set :hostname, @config.host
      if blocking
        MCSMP::HTTPConnector.run!
        stop
      else
        Thread.new { MCSMP::HTTPConnector.run! }
      end
    end

    def autostart
      @server_runners.each do |r|
        unless File.exist?(File.join(r.instance.physical_path, '.autostart'))
          next
        end

        r.start_async
      end
    end
  end
end
