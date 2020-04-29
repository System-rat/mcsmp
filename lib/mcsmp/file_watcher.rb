# frozen_string_literal: true

module MCSMP
  # Utility methods and classes
  module Util
    # Watches a file for changes via polling and runs a block when the file changes
    class FileWatcher
      def initialize(file_path, interval: 10, &on_change)
        @file_path = file_path
        @interval = interval
        @on_change = on_change
      end
    end
  end
end
