# frozen_string_literal: true

require 'open3'

module MCSMP
  # A class responsible for running a ServerInstance
  class ServerRunner
    attr_reader :instance
    attr_accessor :jvm_arguments

    def initialize(server_instance, java_executable: 'java', jvm_arguments: nil, log_limit: 100)
      unless server_instance.exists?
        raise ArgumentError, "ServerInstance doesn't exist on the machine,"\
                             'create it first before attempting to run it.'
      end

      @instance = server_instance
      @log_limit = log_limit
      @log = []
      @log_mutex = Mutex.new
      @java_executable = java_executable
      @jvm_arguments =
        jvm_arguments ||
        MCSMP::Util::JVMArguments.new
    end

    def running?
      @server_thread&.alive?
    end

    # Start the server in sync mode, the parent ruby process' stdin, stdout
    # and stderr are attached to the java instance
    #
    # @note this will block the current thread until the server is stopped
    def start_sync
      return if running?

      jar_path = File.join(@instance.physical_path, 'server.jar')
      Process.wait(Process.spawn(
                     "#{@java_executable} #{arguments} -jar #{jar_path}",
                     chdir: @instance.physical_path
                   ))
    end

    # Start the server in the background, writing all output to the @log
    # variable. Stdin writing is achieved using the ServerRunner#send_text
    # method.
    def start_async(&on_read)
      return if running?

      jar_path = File.join(@instance.physical_path, 'server.jar')
      stdin, stdout, thread = Open3.popen2e(
        "#{@java_executable} #{arguments} -jar #{jar_path}",
        chdir: @instance.physical_path
      )
      @log = []
      start_log_reader(stdout, thread, &on_read)
      instance.start_watcher
      @stdin = stdin
      @server_thread = thread
    end

    def stop
      return unless running?
      return if @stdin.nil?

      @stdin.puts 'stop'
      @stdin = nil
      @server_thread.join
    end

    def send_text(text = '')
      return if @stdin.nil?

      @stdin.puts(text)
    end

    def to_json(*args)
      {
        running: running?,
        instance: instance
      }.to_json(args)
    end

    def log
      logs = []
      @log_mutex.synchronize do
        logs = @log.clone
      end
      logs
    end

    private

    def start_log_reader(stdout, thread)
      Thread.new do
        loop do
          break unless thread.alive?

          begin
            data = stdout.readline
          rescue EOFError
            break
          end
          @log_mutex.synchronize do
            @log.push(data)
            @log.drop(@log.size - @log_limit) if @log.size > @log_limit
          end
          yield(data) if block_given?
        end
      end
    end

    def arguments
      args = @jvm_arguments.to_s
      if File.exist?(File.join(@instance.physical_path, 'arguments.txt'))
        args =
          File.open(
            File.join(@instance.physical_path, 'arguments.txt'), 'r'
          ) { |f| f.read.gsub("\n", '') }
      end
      args
    end
  end
end
