# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # Calls `recalculate_state` on each shipment in memory.
      class RecalculateShipmentStates
        def call(context)
          context.order.shipments.each(&:recalculate_state)

          yield context
        end
      end
    end
  end
end
