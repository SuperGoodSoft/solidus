# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # Sets `order.shipment_total` to the sum of its shipments' costs.
      class ShipmentTotal
        def call(context)
          order = context.order
          order.shipment_total = order.shipments.to_a.sum(&:cost)

          yield context
        end
      end
    end
  end
end
