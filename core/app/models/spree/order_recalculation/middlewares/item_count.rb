# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # Sets `order.item_count` to the sum of its line items' quantities.
      class ItemCount
        def call(context)
          order = context.order
          order.item_count = order.line_items.to_a.sum(&:quantity)

          yield context
        end
      end
    end
  end
end
