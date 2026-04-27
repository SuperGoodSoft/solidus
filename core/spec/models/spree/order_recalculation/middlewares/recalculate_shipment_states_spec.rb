# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::RecalculateShipmentStates do
  let!(:store) { create(:store) }
  let(:order) { create(:order_with_line_items) }
  let(:context) { Spree::OrderRecalculation::Context.new(order: order) }

  it "yields the context to the continuation" do
    expect { |b| described_class.new.call(context, &b) }.to yield_with_args(context)
  end

  it "yields exactly once" do
    expect { |b| described_class.new.call(context, &b) }.to yield_control.once
  end

  it "calls recalculate_state on each shipment" do
    shipment = order.shipments.first
    allow(shipment).to receive(:recalculate_state)

    described_class.new.call(context) { |_ctx| }

    expect(shipment).to have_received(:recalculate_state)
  end

  it "does not make manipulative database queries" do
    order # warm up factory setup before asserting no queries

    expect { described_class.new.call(context) { |_ctx| } }
      .not_to make_database_queries(manipulative: true)
  end
end
