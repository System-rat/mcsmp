# frozen_string_literal: true

require 'mcsmp/version'
require 'fileutils'

# MineCraft-ServerManagementPlatform main module
module MCSMP
  class Error < StandardError; end
  autoload :ConnectorConfig, 'mcsmp/connector_config'
  autoload :Connector, 'mcsmp/connector'
  autoload :ServerProperties, 'mcsmp/server_properties'
  autoload :MineCraftVersion, 'mcsmp/minecraft_versioning'
  autoload :ServerInstance, 'mcsmp/server_instance'
  autoload :ServerRunner, 'mcsmp/server_runner'
  autoload :HTTPConnector, 'mcsmp/http_connector'

  # Utility methods and classes
  module Util
    autoload :FileWatcher, 'mcsmp/util/file_watcher'
    autoload :ProgressBar, 'mcsmp/util/download_progress_bar'
    autoload :JVMArguments, 'mcsmp/util/jvm_arguments'

    module_function

    def get_instances(path = File.absolute_path(FileUtils.pwd))
      entries = Dir.entries(path).select do |entry|
        File.directory?(File.join(path, entry)) &&
          entry != '.' && entry != '..' &&
          File.exist?(File.join(path, entry, 'server.jar'))
      end
      entries.filter_map do |dir|
        server_path = File.join(path, dir)
        instance = nil
        begin
          instance = MCSMP::ServerInstance.from_existing(server_path)
        rescue StandardError => e
          warn e
        end
        instance
      end
    end

    def get_runners(instances)
      runners = []
      instances.each do |instance|
        next unless instance.exists?

        runner = MCSMP::ServerRunner.new(instance)
        runners.push(runner)
      end
      runners
    end
  end
end
