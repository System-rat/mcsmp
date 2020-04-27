# frozen_string_literal: true

module MCSMP
  # Holds methods for verifying types
  module Verifications
    # Tests if the type is a boolean
    def boolean
      lambda do |x, convert = false|
        if convert
          return true if x == 'true'
          return false if x == 'false'

          return false
        end
        x.to_s == 'true' || x.to_s == 'false'
      end
    end

    # Tests if the type is a string
    def string
      lambda do |x, convert = false|
        return x.to_s if convert

        x.to_s == x
      end
    end

    # Tests if the type is an integer
    def integer
      lambda do |x, convert = false|
        return x.to_i if convert

        x.is_a? Integer
      end
    end

    # Tests if a string matches all possible values allowed
    def enum(possible_values)
      lambda do |x, convert = false|
        return string.call(x) if convert

        string.call(x) && possible_values.include?(x)
      end
    end
  end

  # Represents the properties of a MineCraft server
  class ServerProperties
    extend Verifications

    @available_fields = {
      allow_flight: boolean,
      allow_nether: boolean,
      broadcast_console_to_ops: boolean,
      broadcast_rcon_to_ops: boolean,
      difficulty: enum(%w[peaceful easy normal hard]),
      enable_command_block: boolean,
      enable_jmx_monitoring: boolean,
      enable_rcon: boolean,
      sync_chunk_writes: boolean,
      enable_query: boolean,
      force_gamemode: boolean,
      function_permission_level: integer,
      gamemode: enum(%w[survival creative adventure spectator]),
      generate_structures: boolean,
      generator_setting: string,
      hardcore: boolean,
      level_name: string,
      level_seed: string,
      level_type: enum(%w[default flat largebiomes amplified buffet]),
      max_build_height: integer,
      max_players: integer,
      max_tick_time: integer,
      max_world_size: integer,
      motd: string,
      network_compression_threshold: integer,
      online_mode: boolean,
      op_permission_level: integer,
      player_idle_timeout: integer,
      pvp: boolean,
      query__port: integer,
      rcon__password: string,
      rcon__port: integer,
      resource_pack: string,
      resource_pack_sha1: string,
      server_ip: string,
      server_port: integer,
      snooper_enabled: boolean,
      spawn_animals: boolean,
      spawn_monsters: boolean,
      spawn_npcs: boolean,
      spawn_protection: integer,
      use_native_transport: boolean,
      view_distance: integer,
      white_list: boolean,
      enforce_whitelist: boolean
    }
    class << self
      attr_reader :available_fields
    end

    # Represents an error in the getting or setting of properties
    class PropertyError < ArgumentError
      def initialize
        @message = 'Property does not exist or is malformed'
      end
    end

    def initialize(properties = {})
      @properties = {}
      properties.each_key do |property_key|
        if self.class.available_fields.key?(property_key) &&
           (self.class.available_fields[property_key]
              .call(properties[property_key]) || properties[property_key].nil?)
          @properties[property_key] = properties[property_key]
        else
          raise PropertyError
        end
      end
    end

    def to_config
      config_output = String.new
      @properties.each do |k, v|
        line = k.to_s.sub('__', '.').sub('_', '-') + '=' + v.to_s
        config_output << line + "\n"
      end
      config_output
    end

    def self.from_config(data)
      config_lines = data.lines.filter! { |line| !line.start_with? '#' }
      properties = {}
      config_lines.each do |line|
        next if line.start_with? '='

        key, value = line.strip.split '='
        key = key.sub('.', '__').sub('-', '_').to_sym
        next unless available_fields.key? key

        value &&= available_fields[key].call value, true
        properties[key] = value
      end
      new properties
    end

    def []=(key, value)
      unless self.class.available_fields.key?(key) &&
             (self.class.available_fields[key].call(value) || value.nil?)
        raise PropertyError
      end

      @properties[key] = value
    end

    def [](property)
      raise PropertyError unless @properties.key? property

      @properties[property]
    end
  end
end
