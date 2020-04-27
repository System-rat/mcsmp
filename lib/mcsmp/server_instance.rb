# frozen_string_literal: true

module MCSMP
  # A MineCraft server instance that synchronizes it's properties with
  # the physical server instance on the machine
  class ServerInstance
    attr_accessor :version, :server_name, :properties

    def self.from_version(version, server_name)
      new(version, server_name, MCSMP::ServerProperties.new)
    end

    def self.from_latest(server_name)
      latest_release = MCSMP::MineCraftVersion.latest_release
      new(latest_release, server_name, MCSMP::ServerProperties.new)
    end

    def self.from_latest_snapshot(server_name)
      latest_snapshot = MCSMP::MineCraftVersion.latest_snapshot
      new(latest_snapshot, server_name, MCSMP::ServerProperties.new)
    end

    def initialize(version, server_name, properties)
      @version = version
      @server_name = server_name
      @properties = properties
      @exists = false
    end

    def exists?
      @exists
    end

    def synchronize; end

    def initialize_synchronizer; end
  end
end
