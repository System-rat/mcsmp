# frozen_string_literal: true

require 'digest/sha2'
require 'time'

module MCSMP
  class ConnectorConfig
    attr_accessor :port, :host, :is_local, :connection_secret, :path

    def initialize(
      port = 1337,
      host = 'localhost',
      path = File.absolute_path(FileUtils.pwd),
      is_local = true,
      secret = nil
    )
      @port = port
      @host = host
      @path = path
      @is_local = is_local
      @connection_secret = secret || generate_secret
    end

    def generate_secret
      Digest::SHA2.hexdigest Time.now.to_i.to_s
    end

    def generate_secret!
      @connection_secret = generate_secret
    end
  end
end

