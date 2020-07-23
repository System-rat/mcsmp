# frozen_string_literal: true

require 'json'

module MCSMP
  require 'sinatra/base'
  # The HTTP connector
  class HTTPConnector < Sinatra::Base

    set :port, 1337
    set :hostname, 'localhost'

    def self.configuration=(conf)
      @conf = conf
    end

    def self.configuration
      @conf
    end

    helpers do
      def runner_with_name(name)
        Connector.instance.server_runners.find { |r| r.instance.server_name == name }
      end

      def connector
        Connector.instance
      end
    end

    before do
      if !connector.config.is_local &&
         request.env['HTTP_AUTHORIZATION'] != connector.config.connection_secret
        halt 403
      end
    end

    get '/available_servers' do
      filter = params['name']
      runners = connector.server_runners
      if filter
        runners = runners.filter do |i|
          i.server_name.downcase.include? filter.downcase
        end
      end
      {
        data: runners
      }.to_json
    end

    get '/running_servers' do
      runners = connector.server_runners
      runners = runners.filter(&:running?)
      {
        data: runners
      }.to_json
    end

    get '/get_log' do
      pass unless params['name']
      limit = params['limit'] || 100
      name = params['name']

      runner = runner_with_name(name)
      if runner
        { log: runner.log.last(limit).join }.to_json
      else
        [500, { message: 'Server does not exist' }.to_json]
      end
    end

    get '/get_properties/:name' do |name|
      runner = runner_with_name(name)
      next [500, 'Server does not exist.'] unless runner

      {
        properties: runner.instance.properties
      }.to_json
    end

    post '/set_properties/:name' do |name|
      begin
        runner = runner_with_name(name)
        next [500, 'Server does not exist.'] unless runner

        body = request.body.read
        data = JSON.parse(body)
        data['properties']&.each_key do |property|
          runner.instance.properties[property.to_sym] = data['properties'][property]
        end
        runner.instance.write_properties if data['properties']
      rescue MCSMP::ServerProperties::PropertyError
        runner&.instance&.refresh_properties
        halt [500, 'Incorrect properties']
      rescue JSON::JSONError
        halt [500, 'Incorrect JSON' + body]
      end
    end

    post '/stop_server/:name' do |name|
      runner = runner_with_name(name)
      next [500, 'Server does not exist.'] unless runner

      runner.stop
      {
        new_state: runner
      }.to_json
    end

    post '/start_server/:name' do |name|
      runner = runner_with_name(name)
      next [500, 'Server does not exist.'] unless runner

      runner.start_async
      {
        new_state: runner
      }.to_json
    end

    get '/get_jvm_arguments/:name' do |name|
      runner = runner_with_name(name)
      next [500, 'Server does not exist.'] unless runner

      {
        initial_memory: runner.jvm_arguments.initial_memory,
        max_memory: runner.jvm_arguments.max_memory,
        aggressive: runner.jvm_arguments.aggressive
      }.to_json
    end

    post '/set_jvm_arguments/:name' do |name|
      runner = runner_with_name(name)
      next [500, 'Server does not exist.'] unless runner

      i_memory = params['i_memory'] || runner.jvm_arguments.initial_memory
      m_memory = params['m_memory'] || runner.jvm_arguments.max_memory
      aggressive = params['aggressive'] || runner.jvm_arguments.aggressive
      new_config = MCSMP::Util::JVMArguments
                   .new
                   .with_initial_memory(i_memory)
                   .with_max_memory(m_memory)
      new_config.with_aggressive_optimizations if aggressive
      runner.jvm_arguments = new_config
    end

    post '/set_version/:name' do |name|
      runner = runner_with_name(name)
      next [500, 'Server does not exist.'] unless runner

      version = params['version']
      runner.stop
      runner.instance.download_version(version)
      runner.start_async
      {
        new_state: runner
      }.to_json
    end

    post '/set_latest_version/:name' do |name|
      runner = runner_with_name(name)
      next [500, 'Server does not exist.'] unless runner

      snapshot = params['is_snapshot']
      was_running = runner.running?
      runner.stop('Server updating')
      runner.instance.download_latest(snapshot)
      runner.start_async if was_running
      {
        new_state: runner
      }.to_json
    end

    get '/heartbeat' do
      'Am alive'
    end
  end
rescue LoadError
  warn 'Install sinatra for this to work'
end

