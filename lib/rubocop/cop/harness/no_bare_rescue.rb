# frozen_string_literal: true

module RuboCop
  module Cop
    module Harness
      # Avoid blanket rescues that catch the entire `StandardError` tree.
      #
      # A class-less `rescue` / `rescue => e`, or an explicit
      # `rescue StandardError`/`rescue Exception`, catches every error and
      # hides the specific failure the code should handle. Rescue the
      # specific error class you expect instead.
      #
      # A blanket rescue is allowed as a backstop *after* a specific rescue
      # clause in the same block: the specific clause handles known failures
      # meaningfully, and the blanket clause reports the unexpected ones. It
      # is only flagged when no sibling clause names a specific error class.
      #
      # @example
      #   # bad - sole blanket handler
      #   begin
      #     call_api
      #   rescue => e
      #     Rollbar.error(e)
      #   end
      #
      #   # good - rescue the specific error
      #   begin
      #     call_api
      #   rescue Faraday::Error => e
      #     Rollbar.error(e)
      #   end
      #
      #   # good - blanket rescue as a backstop after a specific clause
      #   begin
      #     call_api
      #   rescue Faraday::Error => e
      #     retry_later(e)
      #   rescue => e
      #     Rollbar.error(e)
      #   end
      class NoBareRescue < Base
        MSG = "[Harness] Blanket rescue catches every `StandardError`. " \
              "Rescue the specific error class you expect (e.g. " \
              "`rescue Faraday::Error => e`). A blanket rescue is allowed " \
              "only as a backstop after a specific rescue clause."

        BROAD_EXCEPTIONS = %w[StandardError Exception].freeze

        def on_resbody(node)
          return unless blanket?(node)
          return if specific_sibling?(node)

          add_offense(node.loc.keyword)
        end

        private

        # A resbody is blanket when it lists no exception class (implicit
        # StandardError) or every listed class is a broad catch-all.
        def blanket?(resbody)
          exceptions = resbody.exceptions
          return true if exceptions.empty?

          exceptions.all? { |const| broad?(const) }
        end

        def specific_sibling?(resbody)
          rescue_node = resbody.parent
          return false unless rescue_node&.rescue_type?

          rescue_node.resbody_branches.any? do |branch|
            !branch.equal?(resbody) && specific?(branch)
          end
        end

        # A resbody is specific when it names at least one non-broad class.
        def specific?(resbody)
          resbody.exceptions.any? { |const| !broad?(const) }
        end

        def broad?(const_node)
          return false unless const_node.const_type?

          BROAD_EXCEPTIONS.include?(const_node.const_name)
        end
      end
    end
  end
end
