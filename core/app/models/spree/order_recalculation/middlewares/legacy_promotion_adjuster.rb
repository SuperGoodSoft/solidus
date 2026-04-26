# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # Invokes the configured promotion adjuster on the order.
      class LegacyPromotionAdjuster
        def call(context)
          Spree::Config.promotions.order_adjuster_class.new(context.order).call(persist: context.persist?)

          yield context
        end
      end
    end
  end
end
