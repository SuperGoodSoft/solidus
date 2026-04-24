# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::Event do
  let!(:store) { create(:store) }
  let(:order) { Spree::Order.create }
  let(:context) { Spree::OrderRecalculation::Context.new(order: order, persist: persist) }

  context "when context.persist? is true" do
    let(:persist) { true }

    it "yields the context to the continuation" do
      expect { |b| described_class.new.call(context, &b) }.to yield_with_args(context)
    end

    it "yields exactly once" do
      expect { |b| described_class.new.call(context, &b) }.to yield_control.once
    end

    it "publishes :order_recalculated on Spree::Bus with the order" do
      allow(Spree::Bus).to receive(:publish)
      described_class.new.call(context) { |_ctx| }
      expect(Spree::Bus).to have_received(:publish).with(:order_recalculated, order: order).once
    end

    it "publishes after the yield completes" do
      allow(Spree::Bus).to receive(:publish)

      described_class.new.call(context) do
        expect(Spree::Bus).not_to have_received(:publish)
      end

      expect(Spree::Bus).to have_received(:publish)
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

    it "does not publish :order_recalculated" do
      allow(Spree::Bus).to receive(:publish)
      described_class.new.call(context) { |_ctx| }
      expect(Spree::Bus).not_to have_received(:publish)
    end
  end
end
