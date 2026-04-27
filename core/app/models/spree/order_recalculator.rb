# frozen_string_literal: true

module Spree
  # Middleware-chain-based recalculator. Opt in by setting
  # `Spree::Config.order_recalculator_class = "Spree::OrderRecalculator"`.
  # Customise behaviour by mutating the configured middleware lists.
  class OrderRecalculator
    attr_reader :order

    def initialize(order)
      @order = order
    end

    def recalculate(persist: true)
      run(Spree::Config.order_recalculation_middlewares, persist: persist)
    end

    def recalculate_payment_state
      run(Spree::Config.payment_state_recalculation_middlewares)
      order.payment_state
    end

    def recalculate_shipment_state
      run(Spree::Config.shipment_state_recalculation_middlewares)
      order.shipment_state
    end

    private

    def run(middlewares, persist: true)
      context = Spree::Config.order_recalculation_context_class.new(order: order, persist: persist)
      Spree::OrderRecalculation::Runner.call(middlewares, context)
    end
  end
end
