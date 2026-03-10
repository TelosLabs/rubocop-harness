# frozen_string_literal: true

module RuboCop
  module Cop
    module Harness
      # Enforces a maximum method length in controllers.
      #
      # Controllers should be thin. Extract long methods into service objects
      # in `app/services/`.
      #
      # @example
      #   # bad
      #   def create
      #     # 11+ lines of logic
      #   end
      #
      #   # good
      #   def create
      #     result = MyService.new(params).call
      #     # short delegation
      #   end
      class ControllerMethodLength < MethodLengthBase
        MSG = '[Harness] `%<method>s` is %<length>d lines (max %<max>d). ' \
              'Extract logic into a service object in app/services/. ' \
              'Use Pattern A (call) or Pattern B (save).'

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
