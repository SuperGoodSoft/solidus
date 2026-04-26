# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::ShipmentTotal do
  let!(:store) { create(:store) }
  let(:order) { create(:order_with_line_items, shipment_cost: 25) }
  let(:context) { Spree::OrderRecalculation::Context.new(order: order) }

  before do
    order.update_columns(shipment_total: 0)
    order.reload
  end

  it "yields the context to the continuation" do
    expect { |b| described_class.new.call(context, &b) }
      .to yield_with_args(context)
  end

  it "yields exactly once" do
    expect { |b| described_class.new.call(context, &b) }
      .to yield_control.once
  end

  it "sets order.shipment_total to the sum of shipment costs" do
    expect { described_class.new.call(context) { |_ctx| } }
      .to change { order.shipment_total }.from(0).to(25)
  end
end
