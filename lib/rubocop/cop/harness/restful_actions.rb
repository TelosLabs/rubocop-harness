# frozen_string_literal: true

module RuboCop
  module Cop
    module Harness
      # Controllers should only define the 7 RESTful actions.
      #
      # Non-standard actions indicate the controller is handling too many
      # responsibilities. Extract them into a new, focused controller.
      #
      # @example
      #   # bad
      #   class UsersController < ApplicationController
      #     def archive
      #       # ...
      #     end
      #   end
      #
      #   # good - extract to a dedicated controller
      #   class Users::ArchivesController < ApplicationController
      #     def create
      #       # ...
      #     end
      #   end
      class RestfulActions < Base
        include VisibilityHelp
        include AllowedMethods

        RESTFUL_ACTIONS = %i[index show new create edit update destroy].to_set.freeze

        MSG = "[Harness] `%<method>s` is not a standard RESTful action. " \
              "Controllers should only define: index, show, new, create, " \
              "edit, update, destroy. Extract into a new controller " \
              "(e.g., %<suggestion>s)."

        def on_def(node)
          return if restful_action?(node.method_name)
          return if allowed_method?(node.method_name)
          return if node_visibility(node) != :public

          add_offense(node, message: build_message(node))
        end

        private

        def restful_action?(name)
          RESTFUL_ACTIONS.include?(name)
        end

        def build_message(node)
          name = node.method_name.to_s
          format(MSG,
            method: name,
            suggestion: suggest_controller(name))
        end

        def suggest_controller(method_name)
          controller_name = method_name.split("_").map(&:capitalize).join
          "#{controller_name}Controller#create"
        end
      end
    end
  end
end
