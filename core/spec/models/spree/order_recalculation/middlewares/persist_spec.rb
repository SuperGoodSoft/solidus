# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::Persist do
  let!(:store) { create(:store) }
  let(:order) { Spree::Order.create }
  let(:context) {
    Spree::OrderRecalculation::Context.new(
      order:,
      persist:
    )
  }

  context "when context.persist? is true" do
    let(:persist) { true }

    it "yields the context to the continuation" do
      expect { |b| described_class.new.call(context, &b) }
        .to yield_with_args(context)
    end

    it "yields exactly once" do
      expect { |b| described_class.new.call(context, &b) }
        .to yield_control.once
    end

    it "calls order.save! after the yield" do
      allow(order).to receive(:save!)

      described_class.new.call(context) do
        expect(order).not_to have_received :save!
      end

      expect(order).to have_received :save!
    end

    it "persists shipment amounts after the yield" do
      shipment = instance_double(Spree::Shipment, persist_amounts: nil)
      allow(order).to receive(:shipments).and_return([shipment])
      allow(order).to receive(:save!)

      described_class.new.call(context) { |_ctx| }

      expect(shipment).to have_received(:persist_amounts)
    end

    it "enqueues a state-change job when payment_state changes" do
      order.update!(payment_state: "balance_due")
      order.payment_state = "paid"

      expect { described_class.new.call(context) { |_ctx| } }
        .to have_enqueued_job(Spree::StateChangeTrackingJob).with(
          order,
          "balance_due",
          "paid",
          instance_of(ActiveSupport::TimeWithZone),
          "payment"
        )
    end

    it "enqueues a state-change job when shipment_state changes" do
      order.update!(shipment_state: "pending")
      order.shipment_state = "ready"

      expect { described_class.new.call(context) { |_ctx| } }
        .to have_enqueued_job(Spree::StateChangeTrackingJob).with(
          order,
          "pending",
          "ready",
          instance_of(ActiveSupport::TimeWithZone),
          "shipment"
        )
    end

    it "does not enqueue jobs when neither state changed" do
      order.update!(payment_state: "balance_due", shipment_state: "pending")

      expect { described_class.new.call(context) { |_ctx| } }
        .not_to have_enqueued_job(Spree::StateChangeTrackingJob)
    end
  end

  context "when context.persist? is false" do
    let(:persist) { false }

    it "yields the context to the continuation" do
      expect { |b| described_class.new.call(context, &b) }.to yield_with_args(context)
    end

    it "yields exactly once" do
      expect { |b| described_class.new.call(context, &b) }.to yield_control.once
    end

    it "does not call order.save!" do
      expect(order).not_to receive(:save!)
      described_class.new.call(context) { |_ctx| }
    end

    it "does not persist shipment amounts" do
      shipment = instance_double(Spree::Shipment, persist_amounts: nil)
      allow(order).to receive(:shipments).and_return([shipment])

      described_class.new.call(context) { |_ctx| }

      expect(shipment).not_to have_received(:persist_amounts)
    end

    it "does not enqueue state-change jobs" do
      order.update!(payment_state: "balance_due", shipment_state: "pending")
      order.payment_state = "paid"
      order.shipment_state = "ready"

      expect { described_class.new.call(context) { |_ctx| } }
        .not_to have_enqueued_job(Spree::StateChangeTrackingJob)
    end
  end
end
