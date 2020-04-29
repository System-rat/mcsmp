# frozen_string_literal: true
require 'json'
require 'zip'

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

    def self.from_existing(path)
      version = get_version_from_jar(File.join(path, 'server.jar'))
      mc_version = MCSMP::MineCraftVersion.specific_version(version)
      server_config =
        MCSMP::ServerProperties.from_file(File.join(path, 'server.properties'))
      ServerInstance.new(mc_version,
                         File.basename(path),
                         server_config,
                         exists: true)
    end

    def self.get_version_from_jar(jar_path)
      archive = Zip::File.open(jar_path)
      version_text = archive.glob('version.json')
                            .first
                            .get_input_stream
                            .read
      archive.close
      JSON.parse(version_text)['id']
    end

    def initialize(version, server_name, properties, exists: false)
      @version = version
      @server_name = server_name
      @properties = properties
      @exists = exists
    end

    def exists?
      @exists
    end

    def synchronize; end

    def initialize_synchronizer; end
  end
end
