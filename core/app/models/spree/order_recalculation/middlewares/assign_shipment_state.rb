# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # Sets `order.shipment_state` based on the shipments' states.
      class AssignShipmentState
        def call(context)
          order = context.order
          order.shipment_state = determine_shipment_state(order)

          yield context
        end

        private

        def determine_shipment_state(order)
          return "backorder" if order.backordered?

          shipment_states = order.shipments.states
          if shipment_states.size > 1
            "partial"
          else
            shipment_states.first
          end
        end
      end
    end
  end
end
