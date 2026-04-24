# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # This middleware wraps the remainder of the chain in an
      # `order.transaction` block.
      class Transaction
        def call(context)
          context.order.transaction do
            yield context
          end
        end
      end
    end
  end
end
