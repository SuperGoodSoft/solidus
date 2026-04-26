# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::ItemTotals do
  let!(:store) { create(:store) }
  let(:order) { create(:order_with_line_items) }
  let(:line_item) { order.line_items.first }
  let(:context) { Spree::OrderRecalculation::Context.new(order: order) }

  before do
    create(:adjustment, source: nil, adjustable: line_item, order: order, amount: -5)
    line_item.reload
  end

  it "yields the context to the continuation" do
    expect { |b| described_class.new.call(context, &b) }
      .to yield_with_args(context)
  end

  it "yields exactly once" do
    expect { |b| described_class.new.call(context, &b) }
      .to yield_control.once
  end

  it "recalculates adjustment totals on changed line items" do
    expect { described_class.new.call(context) { |_ctx| } }
      .to change { line_item.adjustment_total }.from(0).to(-5)
  end
end
