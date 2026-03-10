# frozen_string_literal: true

module RuboCop
  module Cop
    module Harness
      # Service objects must define a `call` or `save` instance method.
      #
      # This enforces the two accepted service patterns:
      # - Pattern A: `call` for operations that return data
      # - Pattern B: `save` for operations that persist data
      #
      # @example
      #   # bad
      #   class OrderProcessor < ApplicationService
      #     def process
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   class OrderProcessor < ApplicationService
      #     def call
      #       # ...
      #     end
      #   end
      class ServiceInterface < Base
        MSG = "[Harness] `%<class_name>s` does not define a `%<methods>s` " \
              "method. Service objects must implement Pattern A (call) " \
              "or Pattern B (save)."

        def on_class(node)
          return if nested_class?(node)
          return if defines_required_method?(node)

          add_offense(node.identifier, message: build_message(node))
        end

        private

        def required_methods
          @required_methods ||=
            cop_config.fetch("RequiredMethods", %w[call save]).map(&:to_sym)
        end

        def defines_required_method?(class_node)
          method_nodes(class_node).any? do |def_node|
            required_methods.include?(def_node.method_name)
          end
        end

        def method_nodes(class_node)
          return [] unless class_node.body

          if class_node.body.begin_type?
            class_node.body.each_child_node(:def)
          elsif class_node.body.def_type?
            [class_node.body]
          else
            class_node.body.each_descendant(:def)
          end
        end

        def nested_class?(node)
          node.each_ancestor(:class).any?
        end

        def build_message(node)
          format(MSG,
            class_name: node.identifier.short_name,
            methods: required_methods.join("` or `"))
        end
      end
    end
  end
end
