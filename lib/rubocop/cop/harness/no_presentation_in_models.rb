# frozen_string_literal: true

module RuboCop
  module Cop
    module Harness
      # Models should not contain presentation logic.
      #
      # HTML generation, route helpers, and view-layer methods belong in
      # presenters, decorators, or view helpers — not in the domain layer.
      #
      # @example
      #   # bad
      #   def profile_link
      #     content_tag(:a, name, href: "/users/#{id}")
      #   end
      #
      #   # good - move to a presenter or view helper
      #   class UserPresenter
      #     def profile_link
      #       content_tag(:a, user.name, href: "/users/#{user.id}")
      #     end
      #   end
      class NoPresentationInModels < Base
        include AllowedMethods

        PRESENTATION_METHODS = %i[
          content_tag link_to sanitize
        ].freeze

        # RESTRICT_ON_SEND is intentionally omitted. This cop checks
        # three different patterns with different method names (:include,
        # :content_tag, and any method on ActionController::Base.helpers),
        # so we cannot restrict to a single method list. This is acceptable
        # since the cop only runs on app/models/**/*.rb (limited file set).

        MSG = '[Harness] `%<method>s` is presentation logic in a model. ' \
              'Move to a presenter, decorator, or view helper.'

        MSG_INCLUDE = '[Harness] `%<source>s` brings presentation logic ' \
                      'into a model. Move to a presenter, decorator, or view helper.'

        # @!method url_helpers_include?(node)
        def_node_matcher :url_helpers_include?,
          '(send nil? :include (send (send (send (const nil? :Rails) :application) :routes) :url_helpers))'

        # @!method action_controller_helpers_call?(node)
        def_node_matcher :action_controller_helpers_call?,
          '(send (send (const (const nil? :ActionController) :Base) :helpers) _ ...)'

        def on_send(node)
          check_presentation_methods(node)
          check_url_helpers_include(node)
          check_action_controller_helpers(node)
        end

        private

        def check_presentation_methods(node)
          return unless PRESENTATION_METHODS.include?(node.method_name)
          return if allowed_method?(node.method_name)

          add_offense(
            node.loc.selector,
            message: format(MSG, method: node.method_name)
          )
        end

        def check_url_helpers_include(node)
          return unless url_helpers_include?(node)

          add_offense(
            node,
            message: format(MSG_INCLUDE, source: 'Rails.application.routes.url_helpers')
          )
        end

        def check_action_controller_helpers(node)
          return unless action_controller_helpers_call?(node)

          add_offense(
            node.loc.selector,
            message: format(MSG, method: 'ActionController::Base.helpers')
          )
        end
      end
    end
  end
end
