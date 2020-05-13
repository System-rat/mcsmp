# frozen_string_literal: true

module MCSMP
  module Util
    # Watches a file for changes via polling and runs a
    # block when the file changes
    class FileWatcher
      attr_accessor :file_path

      def initialize(file_path, interval: 1, &on_change)
        @file_path = File.absolute_path(file_path)
        @interval = interval
        @on_change = on_change
        @running_thread = nil
        @last_mod_time = File.mtime(@file_path)
      end

      def start
        @running_thread = Thread.new do
          loop do
            do_watch
            sleep @interval
          end
        end
      end

      def stop
        return unless @running_thread

        @running_thread.exit
        @running_thread = nil
      end

      def running?
        !@running_thread.nil? && @running_thread.alive?
      end

      private

      def do_watch
        return stop unless File.exist?(@file_path)

        return unless changed?

        @on_change.call(@file_path, File.mtime(@file_path))
        update_mtime
      end

      def changed?
        @last_mod_time != File.mtime(@file_path)
      end

      def update_mtime
        @last_mod_time = File.mtime(@file_path)
      end
    end
  end
end
