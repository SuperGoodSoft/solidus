# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # Assigns each shipment's cost from its selected shipping rate.
      class ShipmentAmounts
        def call(context)
          context.order.shipments.each(&:assign_amounts)

          yield context
        end
      end
    end
  end
end
