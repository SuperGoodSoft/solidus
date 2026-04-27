# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::CompletedState do
  let!(:store) { create(:store) }
  let(:order) { create(:order_with_line_items) }
  let(:context) { Spree::OrderRecalculation::Context.new(order: order, persist: persist) }
  let(:persist) { true }

  let(:payment_recorder) { [] }
  let(:shipment_recorder) { [] }

  before do
    payment_stub = Class.new {
      define_method(:call) do |ctx, &inner|
        ctx.order.instance_variable_get(:@_test_payment_recorder) << :payment
        inner.call(ctx)
      end
    }
    shipment_stub = Class.new {
      define_method(:call) do |ctx, &inner|
        ctx.order.instance_variable_get(:@_test_shipment_recorder) << :shipment
        inner.call(ctx)
      end
    }
    stub_const("CompletedStateTest::PaymentStub", payment_stub)
    stub_const("CompletedStateTest::ShipmentStub", shipment_stub)

    order.instance_variable_set(:@_test_payment_recorder, payment_recorder)
    order.instance_variable_set(:@_test_shipment_recorder, shipment_recorder)

    payment_list = Spree::Core::ClassConstantizer::List.new
    payment_list << "CompletedStateTest::PaymentStub"
    shipment_list = Spree::Core::ClassConstantizer::List.new
    shipment_list << "CompletedStateTest::ShipmentStub"

    allow(Spree::Config).to receive(:payment_state_recalculation_middlewares).and_return(payment_list)
    allow(Spree::Config).to receive(:shipment_state_recalculation_middlewares).and_return(shipment_list)
  end

  context "when the order is completed" do
    before { allow(order).to receive(:completed?).and_return(true) }

    it "yields the context to the continuation" do
      expect { |b| described_class.new.call(context, &b) }.to yield_with_args(context)
    end

    it "yields exactly once" do
      expect { |b| described_class.new.call(context, &b) }.to yield_control.once
    end

    it "runs the payment-state sub-chain" do
      described_class.new.call(context) { |_ctx| }

      expect(payment_recorder).to eq([:payment])
    end

    it "runs the shipment-state sub-chain" do
      described_class.new.call(context) { |_ctx| }

      expect(shipment_recorder).to eq([:shipment])
    end

    it "calls update_state on each shipment when persist? is true" do
      shipment = order.shipments.first
      allow(shipment).to receive(:update_state)

      described_class.new.call(context) { |_ctx| }

      expect(shipment).to have_received(:update_state)
    end

    context "when context.persist? is false" do
      let(:persist) { false }

      it "does not call update_state on shipments" do
        shipment = order.shipments.first
        allow(shipment).to receive(:update_state)

        described_class.new.call(context) { |_ctx| }

        expect(shipment).not_to have_received(:update_state)
      end

      it "still runs both sub-chains" do
        described_class.new.call(context) { |_ctx| }

        expect(payment_recorder).to eq([:payment])
        expect(shipment_recorder).to eq([:shipment])
      end
    end
  end

  context "when the order is not completed" do
    before { allow(order).to receive(:completed?).and_return(false) }

    it "yields the context to the continuation" do
      expect { |b| described_class.new.call(context, &b) }.to yield_with_args(context)
    end

    it "does not run the payment-state sub-chain" do
      described_class.new.call(context) { |_ctx| }

      expect(payment_recorder).to be_empty
    end

    it "does not run the shipment-state sub-chain" do
      described_class.new.call(context) { |_ctx| }

      expect(shipment_recorder).to be_empty
    end

    it "does not call update_state on shipments" do
      shipment = order.shipments.first
      allow(shipment).to receive(:update_state)

      described_class.new.call(context) { |_ctx| }

      expect(shipment).not_to have_received(:update_state)
    end
  end
end
