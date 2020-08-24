# frozen_string_literal: true

require 'json'
require 'zip'
require 'fileutils'

module MCSMP
  # A MineCraft server instance that synchronizes it's properties with
  # the physical server instance on the machine
  class ServerInstance
    attr_accessor :version, :server_name, :properties, :physical_path

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
      path = File.absolute_path(path)
      version = get_version_from_jar(File.join(path, 'server.jar'))
      mc_version = MCSMP::MineCraftVersion.specific_version(version)
      server_config =
        MCSMP::ServerProperties.from_file(File.join(path, 'server.properties'))
      ServerInstance.new(mc_version,
                         File.basename(path),
                         server_config,
                         exists: true,
                         physical_path: path)
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

    def initialize(version,
                   server_name,
                   properties,
                   exists: false,
                   physical_path: nil)
      @version = version
      @server_name = server_name
      @properties = properties
      @exists = exists
      @physical_path = physical_path
      create_watcher unless physical_path.nil?
    end

    def create_at_path(parent_dir)
      return if exists?

      path = File.join(parent_dir, @server_name)
      raise IOError, 'Server name already exists' unless !File.exist? path
      FileUtils.mkdir(path)
      @physical_path = path
      write_properties
      File.open(File.join(path, 'eula.txt'), 'w') do |eula|
        eula.write('eula=true')
      end
      print 'Downloading: '
      @version.download_information.download(
        File.join(path, 'server.jar'),
        &MCSMP::Util::ProgressBar.new(@version.download_information.size).start
      )
      puts ' Done!'
      @exists = true
      create_watcher
    end
    
    def delete
      return if !exists?
      
      FileUtils.remove_dir physical_path
    end

    def exists?
      @exists
    end

    def download_version(new_version)
      return @version if new_version == @version.version

      @version = MCSMP::MineCraftVersion.specific_version(new_version)
      @version.download_information.download(File.join(@physical_path, 'server.jar'))
      @version
    end

    def download_latest(is_snapshot)
      if (is_snapshot &&
          @version.version == MCSMP::MineCraftVersion.latest_snapshot.version) ||
         (!is_snapshot &&
          @version.version == MCSMP::MineCraftVersion.latest_release.version)
        return @version
      end

      @version = MCSMP::MineCraftVersion.latest_snapshot if is_snapshot
      @version = MCSMP::MineCraftVersion.latest_release unless is_snapshot
      @version.download_information.download(File.join(@physical_path, 'server.jar'))
      @version
    end

    def needs_to_update(is_snapshot)
      if is_snapshot
        version.version != MCSMP::MineCraftVersion.latest_snapshot.version
      else
        version.version != MCSMP::MineCraftVersion.latest_release.version
      end
    end

    def refresh_properties
      return if physical_path.nil?

      @properties =
        MCSMP::ServerProperties.from_file(
          File.join(physical_path, 'server.properties')
        )
    end

    def write_properties
      return if physical_path.nil?

      stop_watcher
      File.open(File.join(physical_path, 'server.properties'), 'w') do |file|
        file.write(@properties.to_config)
      end
      start_watcher
    end

    def start_watcher
      watcher&.start
    end

    def stop_watcher
      watcher&.stop
    end

    def create_watcher
      @watcher =
        MCSMP::Util::FileWatcher.new(
          File.join(@physical_path, 'server.properties')
        ) do |file|
          @properties = MCSMP::ServerProperties.from_file(file)
        end
    end

    def to_json(*args)
      {
        server_name: @server_name,
        version: {
          id: @version.version,
          is_snapshot: @version.is_snapshot
        },
        exists: @exists
      }.to_json(args)
    end

    private

    attr_reader :watcher
  end
end
