# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::TaxAdjustments do
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

  it "invokes the configured tax adjuster on the order" do
    adjuster = instance_double(Spree::Config.tax_adjuster_class)
    allow(Spree::Config.tax_adjuster_class)
      .to receive(:new).with(order).and_return(adjuster)
    allow(adjuster).to receive(:adjust!)

    described_class.new.call(context) { |_ctx| }

    expect(adjuster).to have_received(:adjust!)
  end
end
