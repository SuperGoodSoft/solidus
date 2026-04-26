# frozen_string_literal: true

module Spree
  module OrderRecalculation
    module Middlewares
      # Recalculates per-item totals for each line item and shipment,
      # assigning the resulting totals back to any items that changed.
      class ItemTotals
        def call(context)
          order = context.order
          [*order.line_items, *order.shipments].each do |item|
            Spree::Config.item_total_class.new(item).recalculate!

            next unless item.changed?

            item.assign_attributes(
              promo_total: item.promo_total,
              included_tax_total: item.included_tax_total,
              additional_tax_total: item.additional_tax_total,
              adjustment_total: item.adjustment_total
            )
          end

          yield context
        end
      end
    end
  end
end
