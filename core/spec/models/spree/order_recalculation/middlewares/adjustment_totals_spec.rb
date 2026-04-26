# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::AdjustmentTotals do
  let!(:store) { create(:store) }
  let(:order) { create(:order_with_line_items, shipment_cost: 20) }
  let(:context) { Spree::OrderRecalculation::Context.new(order: order) }

  before do
    order.line_items.first.adjustment_total = -3
    order.line_items.first.additional_tax_total = 1
    order.shipments.first.adjustment_total = -2
    order.item_total = 10
    order.shipment_total = 20
  end

  it "yields the context to the continuation" do
    expect { |b| described_class.new.call(context, &b) }
      .to yield_with_args(context)
  end

  it "yields exactly once" do
    expect { |b| described_class.new.call(context, &b) }
      .to yield_control.once
  end

  it "sums adjustment_total across items and order-level adjustments" do
    expect { described_class.new.call(context) { |_ctx| } }
      .to change { order.adjustment_total }.to(-5)
  end

  it "sums additional_tax_total across items" do
    expect { described_class.new.call(context) { |_ctx| } }
      .to change { order.additional_tax_total }.to(1)
  end

  it "sets order.total to item_total + shipment_total + adjustment_total" do
    expect { described_class.new.call(context) { |_ctx| } }
      .to change { order.total }.to(25)
  end

  it "ignores adjustments marked for destruction" do
    create(:adjustment, order: order, adjustable: order, source: nil, amount: 100)
    order.adjustments.reload.first.mark_for_destruction

    expect { described_class.new.call(context) { |_ctx| } }
      .to change { order.adjustment_total }.to(-5)
  end
end
