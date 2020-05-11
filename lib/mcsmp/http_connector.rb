# frozen_string_literal: true

require 'json'

module MCSMP
  require 'sinatra/base'
  # The HTTP connector
  class HTTPConnector < Sinatra::Base

    set :port, 1337

    def self.configuration=(conf)
      @conf = conf
    end

    def self.configuration
      @conf
    end

    before do
      if request.env['HTTP_AUTHORIZATION'] != settings.configuration[:secret]
        halt 403
      end
    end

    get '/available_servers' do
      filter = params['name']
      runners = settings.configuration[:runners]
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
      runners = settings.configuration[:runners]
      runners = runners.filter(&:running?)
      {
        data: runners
      }.to_json
    end

    get '/get_log' do
      pass unless params['name']
      limit = params['limit'] || 100
      name = params['name']

      runner = settings.configuration[:runners].find do |r|
        r.instance.server_name == name
      end
      if runner
        { log: runner.log.last(limit).join }.to_json
      else
        [500, { message: 'Server does not exist' }.to_json]
      end
    end

  end
rescue LoadError
  warn 'Install sinatra for this to work'
end

