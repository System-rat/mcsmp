# frozen_string_literal: true

require 'mutex'

module MCSMP
  # A class responsible for running a ServerInstance
  class ServerRunner
    attr_reader :instance, :log, :error_log

    def initialize(server_instance, java_executable: 'java', jvm_arguments: nil)
      unless server_instance.exists?
        raise ArgumentError, "ServerInstance doesn't exist on the machine,"\
                             'create it first before attempting to run it.'
      end

      @instance = server_instance
      @log = []
      @error_log = []
      @log_mutex = Mutex.new
      @java_executable = java_executable
      @jvm_arguments =
        jvm_arguments ||
        MCSMP::Util::JVMArguments.new(java_executable: java_executable)
    end
  end
end
