# frozen_string_literal: true

module RuboCop
  module Cop
    module Harness
      # Enforces a maximum method length in models.
      #
      # Models should focus on persistence, associations, and data integrity.
      # Extract business logic into service objects in `app/services/`.
      #
      # @example
      #   # bad
      #   def calculate_score
      #     # 8+ lines of business logic
      #   end
      #
      #   # good - simple accessor
      #   def full_name
      #     "#{first_name} #{last_name}"
      #   end
      class ModelMethodLength < MethodLengthBase
        MSG = "[Harness] `%<method>s` is %<length>d lines (max %<max>d). " \
              "Models should focus on persistence. Extract business logic " \
              "into a service object in app/services/."

        def on_def(node)
          body = node.body
          return unless body

          length = count_body_lines(body)
          return if length <= max_length

          add_offense(node, message: format(MSG, method: node.method_name, length: length, max: max_length))
        end
      end
    end
  end
end
