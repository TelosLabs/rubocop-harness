# frozen_string_literal: true

module RuboCop
  module Cop
    module Harness
      # Shared logic for method length cops that enforce per-directory limits.
      class MethodLengthBase < Base
        private

        def count_body_lines(node)
          source_lines = node.source.lines
          source_lines.count do |line|
            stripped = line.strip
            !stripped.empty? && !stripped.start_with?("#")
          end
        end

        def max_length
          cop_config["Max"]
        end
      end
    end
  end
end
