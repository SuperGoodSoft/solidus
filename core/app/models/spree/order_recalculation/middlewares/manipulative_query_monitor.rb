# frozen_string_literal: true

require "spree/manipulative_query_monitor"

module Spree
  module OrderRecalculation
    module Middlewares
      # Wraps the remainder of the chain in {Spree::ManipulativeQueryMonitor},
      # which logs a warning when downstream middlewares issue unexpected
      # `INSERT`, `UPDATE`, or `DELETE` queries. Stores that do not want the
      # monitor should `delete` it from the chain.
      class ManipulativeQueryMonitor
        def call(context)
          Spree::ManipulativeQueryMonitor.call do
            yield context
          end
        end
      end
    end
  end
end
