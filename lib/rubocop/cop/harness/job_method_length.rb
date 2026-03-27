# frozen_string_literal: true

module RuboCop
  module Cop
    module Harness
      # Enforces a maximum method length in jobs.
      #
      # Jobs should be thin and delegate to service objects. Keep the
      # `perform` method focused on argument unpacking and delegation.
      #
      # @example
      #   # bad
      #   def perform(user_id)
      #     user = User.find(user_id)
      #     # ... 8+ lines of business logic
      #   end
      #
      #   # good - delegate to a service
      #   def perform(user_id)
      #     user = User.find(user_id)
      #     OnboardUserService.new(user).call
      #   end
      class JobMethodLength < MethodLengthBase
        MSG = '[Harness] `%<method>s` is %<length>d lines (max %<max>d). ' \
              'Jobs should be thin. Delegate to a service object in app/services/.'

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
