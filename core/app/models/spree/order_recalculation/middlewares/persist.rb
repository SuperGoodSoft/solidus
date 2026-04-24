# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # Persists the order after the downstream chain completes. Runs inside
      # `Transaction` (which wraps the chain from slot 2 onward) but outside
      # `ManipulativeQueryMonitor`, so the legitimate `order.save!` does not
      # trip the monitor.
      #
      # When `context.persist?` is false, the post-yield block is a no-op;
      # the chain has still run, but nothing is written to the database.
      #
      # Mirrors {Spree::InMemoryOrderUpdater#persist_totals}: shipment amounts
      # are persisted, state-change tracking jobs are enqueued, and the order
      # is saved.
      class Persist
        def call(context)
          yield context

          return unless context.persist?

          order = context.order
          order.shipments.each(&:persist_amounts)
          log_state_change(order, "payment")
          log_state_change(order, "shipment")
          order.save!
        end

        private

        def log_state_change(order, name)
          state = "#{name}_state"
          previous_state, current_state = order.changes[state]
          return if previous_state == current_state

          Spree::StateChangeTrackingJob.perform_later(
            order,
            previous_state,
            current_state,
            Time.current,
            name
          )
        end
      end
    end
  end
end
