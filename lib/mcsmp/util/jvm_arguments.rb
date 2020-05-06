# frozen_string_literal: true

module MCSMP
  module Util
    # Holds various JVM arguments for easy configuration
    class JVMArguments
      AGGRESSIVE_ARGUMENTS =
        ' -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions '\
        '-XX:MaxGCPauseMillis=50 -XX:+DisableExplicitGC '\
        '-XX:TargetSurvivorRatio=90 -XX:G1NewSizePercent=50 '\
        '-XX:G1MaxNewSizePercent=80 '\
        '-XX:InitiatingHeapOccupancyPercent=10 '\
        '-XX:G1MixedGCLiveThresholdPercent=50 -XX:+AggressiveOpts'

      def initialize
        @initial_memory = '1G'
        @max_memory = '1G'
        @aggressive = false
      end

      def with_initial_memory(memory)
        @initial_memory = memory
        self
      end

      def with_max_memory(memory)
        @max_memory = memory
        self
      end

      def with_aggressive_optimizations
        @aggressive = true
        self
      end

      def to_s
        str = "-Xms#{@initial_memory} -Xmx#{@max_memory}"
        str += AGGRESSIVE_ARGUMENTS if @aggressive
        str
      end
    end
  end
end
