# frozen_string_literal: true

module RuboCop
  module Cop
    module Harness
      # Enforces a maximum method length in models.
      #
      # Models own domain logic (validations, calculations, state transitions)
      # but methods should be small and focused. Decompose long methods into
      # smaller private methods, concerns, or value objects.
      #
      # @example
      #   # bad
      #   def calculate_score
      #     # 8+ lines of logic
      #   end
      #
      #   # good - decomposed into smaller methods
      #   def calculate_score
      #     base_score + bonus_score - penalties
      #   end
      class ModelMethodLength < MethodLengthBase
        MSG = '[Harness] `%<method>s` is %<length>d lines (max %<max>d). ' \
              'Decompose into smaller methods, concerns, or value objects.'

        def on_def(node)
          return if allowed_method?(node.method_name)

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
