# frozen_string_literal: true

require 'mcsmp/version'

# MineCraft-ServerManagementPlatform main module
module MCSMP
  class Error < StandardError; end
  autoload :ConnectorConfig, 'mcsmp/connector_config'
  autoload :ServerProperties, 'mcsmp/server_properties'
  autoload :MineCraftVersion, 'mcsmp/minecraft_versioning'
  autoload :ServerInstance, 'mcsmp/server_instance'
  autoload :ServerRunner, 'mcsmp/server_runner'

  # Utility methods and classes
  module Util
    autoload :FileWatcher, 'mcsmp/util/file_watcher'
    autoload :ProgressBar, 'mcsmp/util/download_progress_bar'
    autoload :JVMArguments, 'mcsmp/util/jvm_arguments'
  end
end
