# frozen_string_literal: true

module MCSMP
  module Util
    # creates a progress bar that returns a proc for use with the version download
    class ProgressBar
      attr_accessor :total_size,
                    :current_size,
                    :threshold

      def initialize(total_size, threshold: 0.05)
        @total_size = total_size
        @threshold = threshold
        @current_size = 0
        @current_threshold = threshold
      end

      def start
        $stdout.flush
        lambda do |count|
          @current_size += count
          if (@current_size.to_f / total_size) >= @current_threshold
            print '='
            $stdout.flush
            @current_threshold += threshold
          end
        end
      end
    end
  end
end
