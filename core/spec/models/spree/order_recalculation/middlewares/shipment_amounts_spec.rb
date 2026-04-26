# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::ShipmentAmounts do
  let!(:store) { create(:store) }
  let(:order) { create(:order_with_line_items) }
  let(:context) { Spree::OrderRecalculation::Context.new(order: order) }

  before do
    order.shipments.first.selected_shipping_rate.update!(cost: 200)
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

  it "updates shipment cost to match the selected shipping rate" do
    expect { described_class.new.call(context) { |_ctx| } }
      .to change { order.shipments.first.cost }.from(100).to(200)
  end

  it "does not persist shipment changes" do
    expect { described_class.new.call(context) { |_ctx| } }
      .not_to make_database_queries(manipulative: true)
  end
end
