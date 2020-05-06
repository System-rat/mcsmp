# frozen_string_literal: true

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
        MCSMP::Util::JVMArguments.new
    end

    # Start the server in sync mode, the parent ruby process' stdin, stdout
    # and stderr are attached to the java instance
    #
    # @note this will block the current thread until the server is stopped
    def start_sync
      jar_path = File.join(@instance.physical_path, 'server.jar')
      arguments = @jvm_arguments.to_s
      if File.exist?(File.join(@instance.physical_path, 'arguments.txt'))
        arguments =
          File.open(
            File.join(@instance.physical_path, 'arguments.txt'), 'r'
          ) { |f| f.read.gsub('\n', '') }
      end
      Process.wait(
        Process.spawn(
          "#{@java_executable} #{arguments} -jar #{jar_path}",
          chdir: @instance.physical_path
        )
      )
    end

    def start_async; end
  end
end
