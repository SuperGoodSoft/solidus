# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::ManipulativeQueryMonitor do
  let!(:store) { create(:store) }
  let(:order) { Spree::Order.create }
  let(:context) { Spree::OrderRecalculation::Context.new(order: order) }

  it "yields the context to the continuation" do
    expect { |b| described_class.new.call(context, &b) }
      .to yield_with_args(context)
  end

  it "yields exactly once" do
    expect { |b| described_class.new.call(context, &b) }
      .to yield_control.once
  end

  it "wraps the yield in Spree::ManipulativeQueryMonitor.call" do
    allow(Spree::ManipulativeQueryMonitor)
      .to receive(:call).and_call_original

    described_class.new.call(context) { |_ctx| }

    expect(Spree::ManipulativeQueryMonitor)
      .to have_received(:call).once
  end
end
