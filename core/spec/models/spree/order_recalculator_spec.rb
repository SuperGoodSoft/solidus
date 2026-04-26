# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculator do
  let!(:store) { create(:store) }
  let(:order) { create(:order_with_line_items) }

  describe "#recalculate" do
    it "invokes each middleware in order with the context" do
      recorder = []

      first_class = Class.new {
        define_method(:call) do |ctx, &inner|
          recorder << :first
          inner.call(ctx)
        end
      }
      second_class = Class.new {
        define_method(:call) do |ctx, &inner|
          recorder << :second
          inner.call(ctx)
        end
      }
      stub_const("RecorderMiddlewares::First", first_class)
      stub_const("RecorderMiddlewares::Second", second_class)

      list = Spree::Core::ClassConstantizer::List.new
      list.concat(["RecorderMiddlewares::First", "RecorderMiddlewares::Second"])
      allow(Spree::Config).to receive(:order_recalculation_middlewares).and_return(list)

      described_class.new(order).recalculate

      expect(recorder).to eq([:first, :second])
    end

    it "builds the context using the configured context class" do
      captured_context = nil

      capturing = Class.new {
        define_method(:call) do |ctx, &inner|
          captured_context = ctx
          inner.call(ctx)
        end
      }
      stub_const("CapturingMiddleware", capturing)

      list = Spree::Core::ClassConstantizer::List.new
      list << "CapturingMiddleware"
      allow(Spree::Config).to receive(:order_recalculation_middlewares).and_return(list)

      described_class.new(order).recalculate(persist: false)

      expect(captured_context).to be_a(Spree::OrderRecalculation::Context)
      expect(captured_context.order).to eq(order)
      expect(captured_context.persist?).to be(false)
    end

    it "supports insert_before customisation" do
      recorder = []

      sentinel_class = Class.new {
        define_method(:call) do |ctx, &inner|
          recorder << :sentinel
          inner.call(ctx)
        end
      }
      stub_const("SentinelMiddleware", sentinel_class)

      allow(Spree::OrderRecalculation::Middlewares::Persist).to receive(:new).and_return(
        Class.new {
          define_method(:call) do |ctx, &inner|
            recorder << :persist
            inner.call(ctx)
          end
        }.new
      )

      list = Spree::Core::ClassConstantizer::List.new
      list.concat([
        "Spree::OrderRecalculation::Middlewares::Persist"
      ])
      list.insert_before(
        "Spree::OrderRecalculation::Middlewares::Persist",
        "SentinelMiddleware"
      )
      allow(Spree::Config).to receive(:order_recalculation_middlewares).and_return(list)

      described_class.new(order).recalculate

      expect(recorder).to eq([:sentinel, :persist])
    end

    it "supports insert_after customisation" do
      recorder = []

      sentinel_class = Class.new {
        define_method(:call) do |ctx, &inner|
          recorder << :sentinel
          inner.call(ctx)
        end
      }
      stub_const("SentinelMiddleware", sentinel_class)

      allow(Spree::OrderRecalculation::Middlewares::Persist).to receive(:new).and_return(
        Class.new {
          define_method(:call) do |ctx, &inner|
            recorder << :persist
            inner.call(ctx)
          end
        }.new
      )

      list = Spree::Core::ClassConstantizer::List.new
      list.concat([
        "Spree::OrderRecalculation::Middlewares::Persist"
      ])
      list.insert_after(
        "Spree::OrderRecalculation::Middlewares::Persist",
        "SentinelMiddleware"
      )
      allow(Spree::Config).to receive(:order_recalculation_middlewares).and_return(list)

      described_class.new(order).recalculate

      expect(recorder).to eq([:persist, :sentinel])
    end

    context "end-to-end with the default chain" do
      it "saves the order when persist is true" do
        described_class.new(order).recalculate

        expect(order.reload.persisted?).to be(true)
        expect(order.changed?).to be(false)
      end

      it "publishes :order_recalculated after the save" do
        order # create before stubbing so the factory's initial recalculate runs
        allow(Spree::Bus).to receive(:publish)

        described_class.new(order).recalculate

        expect(Spree::Bus).to have_received(:publish).with(:order_recalculated, order: order)
      end

      it "does not save the order when persist is false" do
        order.email = "changed@example.com"

        described_class.new(order).recalculate(persist: false)

        expect(order.email).to eq("changed@example.com")
        expect(order.reload.email).not_to eq("changed@example.com")
      end

      it "does not publish :order_recalculated when persist is false" do
        order
        allow(Spree::Bus).to receive(:publish)

        described_class.new(order).recalculate(persist: false)

        expect(Spree::Bus).not_to have_received(:publish).with(:order_recalculated, anything)
      end
    end

    context "exception safety" do
      it "rolls back and does not publish when a middleware raises" do
        raising = Class.new {
          def call(_context)
            raise "boom"
          end
        }
        stub_const("RaisingMiddleware", raising)

        list = Spree::Core::ClassConstantizer::List.new
        list.concat(Spree::Config.order_recalculation_middlewares.map { |klass| klass.name })
        list.insert_before(
          "Spree::OrderRecalculation::Middlewares::Persist",
          "RaisingMiddleware"
        )
        allow(Spree::Config).to receive(:order_recalculation_middlewares).and_return(list)

        order # factory setup with default recalculator before Bus is stubbed
        allow(Spree::Bus).to receive(:publish)
        order.email = "rollback@example.com"

        expect { described_class.new(order).recalculate }.to raise_error("boom")
        expect(order.reload.email).not_to eq("rollback@example.com")
        expect(Spree::Bus).not_to have_received(:publish).with(:order_recalculated, anything)
      end

      it "propagates subscriber errors but leaves the order persisted" do
        order # factory setup fires :order_recalculated once; subscribe after
        subscription = Spree::Bus.subscribe(:order_recalculated) { raise "subscriber boom" }

        order.email = "subscriber_propagation@example.com"

        expect { described_class.new(order).recalculate }.to raise_error("subscriber boom")
        expect(order.reload.email).to eq("subscriber_propagation@example.com")
      ensure
        Spree::Bus.unsubscribe(subscription) if subscription
      end
    end
  end

  describe "#recalculate_payment_state" do
    it "runs the payment_state_recalculation_middlewares" do
      recorder = []

      stub = Class.new {
        define_method(:call) do |ctx, &inner|
          recorder << :payment_stub
          inner.call(ctx)
        end
      }
      stub_const("PaymentStateStub", stub)

      list = Spree::Core::ClassConstantizer::List.new
      list << "PaymentStateStub"
      allow(Spree::Config).to receive(:payment_state_recalculation_middlewares).and_return(list)

      described_class.new(order).recalculate_payment_state

      expect(recorder).to eq([:payment_stub])
    end

    it "returns the order's payment_state" do
      allow(Spree::Config).to receive(:payment_state_recalculation_middlewares).and_return(
        Spree::Core::ClassConstantizer::List.new
      )

      order.payment_state = "paid"

      expect(described_class.new(order).recalculate_payment_state).to eq("paid")
    end
  end

  describe "#recalculate_shipment_state" do
    it "runs the shipment_state_recalculation_middlewares" do
      recorder = []

      stub = Class.new {
        define_method(:call) do |ctx, &inner|
          recorder << :shipment_stub
          inner.call(ctx)
        end
      }
      stub_const("ShipmentStateStub", stub)

      list = Spree::Core::ClassConstantizer::List.new
      list << "ShipmentStateStub"
      allow(Spree::Config).to receive(:shipment_state_recalculation_middlewares).and_return(list)

      described_class.new(order).recalculate_shipment_state

      expect(recorder).to eq([:shipment_stub])
    end

    it "returns the order's shipment_state" do
      allow(Spree::Config).to receive(:shipment_state_recalculation_middlewares).and_return(
        Spree::Core::ClassConstantizer::List.new
      )

      order.shipment_state = "ready"

      expect(described_class.new(order).recalculate_shipment_state).to eq("ready")
    end
  end
end
