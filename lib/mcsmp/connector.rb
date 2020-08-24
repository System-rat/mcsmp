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
      @cache_invalidator = Thread.start do
        loop do
          sleep 300
          MCSMP::MineCraftVersion.invalidate_manifest_cache
        end
      end
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
      Thread.kill(@cache_invalidator)
    end

    def create_server(server_name, server_version = nil)
      new_instance = if server_version == nil
        MCSMP::ServerInstance.from_latest(server_name)
      else
        MCSMP::ServerInstance.from_version(server_version, server_name)
      end
      new_instance.create_at_path(path)
      new_runner = MCSMP::ServerRunner.new(new_instance)
      server_instances.push(new_instance)
      server_runners.push(new_runner)
      new_runner
    end

    def delete_server(server_name)
      server = server_runners.find_index { |r| r.instance.server_name == server_name }
      raise ArgumentError, 'Server does not exist' if server.nil?

      warn("WARNING: Deleting server: #{server_name}")
      server_runners[server].delete
      server_runners.delete_at(server)
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
