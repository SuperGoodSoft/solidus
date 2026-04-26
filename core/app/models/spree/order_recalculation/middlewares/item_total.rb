# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # Sets `order.item_total` to the sum of its line items' amounts.
      class ItemTotal
        def call(context)
          order = context.order
          order.item_total = order.line_items.to_a.sum(&:amount)

          yield context
        end
      end
    end
  end
end
