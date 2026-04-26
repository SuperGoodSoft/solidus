# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # If `Spree::Config.recalculate_cart_prices` is true, re-fetches each
      # line item's price from its variant before yielding.
      class LineItemPrices
        def call(context)
          if Spree::Config.recalculate_cart_prices
            context.order.line_items.each(&:recalculate_price)
          end

          yield context
        end
      end
    end
  end
end
