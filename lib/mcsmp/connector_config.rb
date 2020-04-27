require 'digest/sha2'
require 'time'

module MCSMP
  class ConnectorConfig
    attr_accessor :port, :host, :is_local, :connection_secret

    def initialize(port = 1337, host = "localhost", is_local = true, secret = nil)
      @port = port
      @host = host
      @is_local = is_local
      @connection_secret = secret || generate_secret unless is_local
    end

    def generate_secret
      Digest::SHA2.hexdigest Time.now.to_i.to_s
    end

    def generate_secret!
      @connection_secret = generate_secret
    end
  end
end

