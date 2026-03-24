# frozen_string_literal: true

module RuboCop
  module Cop
    module Harness
      # Controllers should not contain ActiveRecord query methods.
      #
      # Move query logic to model scopes or query objects. This keeps
      # controllers thin and focused on request handling.
      #
      # @example
      #   # bad
      #   def index
      #     @users = User.where(active: true).order(:name)
      #   end
      #
      #   # good - model scope
      #   def index
      #     @users = User.active.ordered_by_name
      #   end
      class NoQueriesInControllers < Base
        include AllowedMethods

        QUERY_METHODS = %i[
          where find find_by
          joins includes eager_load preload
          order reorder limit offset group having distinct
          pluck average minimum maximum
          destroy_all update_all delete_all
        ].freeze

        RESTRICT_ON_SEND = QUERY_METHODS

        MSG = "[Harness] `%<method>s` query in controller. Move query " \
              "logic to a model scope or query object."

        def on_send(node)
          return if allowed_method?(node.method_name)
          return unless node.receiver

          add_offense(node.loc.selector, message: format(MSG, method: node.method_name))
        end
        alias on_csend on_send
      end
    end
  end
end
