# frozen_string_literal: true

module Spree
  module OrderRecalculation
    # This class represents the current state of an order recalculation.
    # Instances of it are passed through the middleware chain.
    class Context
      attr_reader :order

      def initialize(order:, persist: true)
        @order = order
        @persist = persist
      end

      def persist?
        !!@persist
      end
    end
  end
end
