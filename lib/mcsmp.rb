# frozen_string_literal: true

require 'mcsmp/version'

# MineCraft-ServerManagementPlatform main module
module MCSMP
  class Error < StandardError; end
  autoload :ConnectorConfig, 'mcsmp/connector_config'
  autoload :ServerProperties, 'mcsmp/server_properties'
  autoload :MineCraftVersion, 'mcsmp/minecraft_versioning'
  autoload :ServerInstance, 'mcsmp/server_instance'
end
