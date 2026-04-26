# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # Sets `order.adjustment_total`, `order.included_tax_total`,
      # `order.additional_tax_total`, and `order.total` from the items'
      # and adjustments' totals.
      class AdjustmentTotals
        def call(context)
          order = context.order
          all_items = order.line_items + order.shipments
          valid_adjustments = order.adjustments.reject(&:marked_for_destruction?)
          order_tax_adjustments = valid_adjustments.select(&:tax?)

          order.adjustment_total = all_items.sum(&:adjustment_total) + valid_adjustments.sum(&:amount)
          order.included_tax_total = all_items.sum(&:included_tax_total) + order_tax_adjustments.select(&:included?).sum(&:amount)
          order.additional_tax_total = all_items.sum(&:additional_tax_total) + order_tax_adjustments.reject(&:included?).sum(&:amount)
          order.total = order.item_total + order.shipment_total + order.adjustment_total

          yield context
        end
      end
    end
  end
end
