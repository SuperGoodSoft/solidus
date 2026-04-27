# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # When the order is completed, runs the payment-state and
      # shipment-state sub-chains. Also calls `update_state` on each shipment
      # when `context.persist?` is true.
      class CompletedState
        def call(context)
          if context.order.completed?
            Spree::OrderRecalculation::Runner.call(
              Spree::Config.payment_state_recalculation_middlewares,
              context
            )

            context.order.shipments.each(&:update_state) if context.persist?

            Spree::OrderRecalculation::Runner.call(
              Spree::Config.shipment_state_recalculation_middlewares,
              context
            )
          end

          yield context
        end
      end
    end
  end
end
