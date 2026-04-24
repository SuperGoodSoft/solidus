# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # If `context.persist?` is true, publishes `:order_recalculated` on
      # `Spree::Bus` after the rest of the chain completes.
      class Event
        def call(context)
          yield context

          return unless context.persist?

          Spree::Bus.publish(:order_recalculated, order: context.order)
        end
      end
    end
  end
end
