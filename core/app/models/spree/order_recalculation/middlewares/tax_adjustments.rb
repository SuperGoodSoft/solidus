# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # Invokes the configured tax adjuster on the order.
      class TaxAdjustments
        def call(context)
          Spree::Config.tax_adjuster_class.new(context.order).adjust!

          yield context
        end
      end
    end
  end
end
