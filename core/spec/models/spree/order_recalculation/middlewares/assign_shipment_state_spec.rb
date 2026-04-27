# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::AssignShipmentState do
  let!(:store) { create(:store) }
  let(:order) { Spree::Order.create }
  let(:context) { Spree::OrderRecalculation::Context.new(order: order) }

  it "yields the context to the continuation" do
    expect { |b| described_class.new.call(context, &b) }.to yield_with_args(context)
  end

  it "yields exactly once" do
    expect { |b| described_class.new.call(context, &b) }.to yield_control.once
  end

  context "when the order is backordered" do
    before { allow(order).to receive(:backordered?).and_return(true) }

    it "assigns backorder" do
      expect { described_class.new.call(context) { |_ctx| } }
        .to change { order.shipment_state }.to("backorder")
    end
  end

  context "when shipments have multiple distinct states" do
    before do
      allow(order).to receive(:backordered?).and_return(false)
      allow(order).to receive_message_chain(:shipments, :states).and_return(["pending", "shipped"])
    end

    it "assigns partial" do
      expect { described_class.new.call(context) { |_ctx| } }
        .to change { order.shipment_state }.to("partial")
    end
  end

  context "when shipments all share one state" do
    before do
      allow(order).to receive(:backordered?).and_return(false)
      allow(order).to receive_message_chain(:shipments, :states).and_return(["ready"])
    end

    it "assigns the shared state" do
      expect { described_class.new.call(context) { |_ctx| } }
        .to change { order.shipment_state }.to("ready")
    end
  end

  context "when there are no shipments" do
    before do
      allow(order).to receive(:backordered?).and_return(false)
      allow(order).to receive_message_chain(:shipments, :states).and_return([])
    end

    it "assigns nil" do
      described_class.new.call(context) { |_ctx| }

      expect(order.shipment_state).to be_nil
    end
  end
end
