# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::LineItemPrices do
  let!(:store) { create(:store) }
  let(:variant) { create(:variant, price: 98) }
  let!(:order) {
    create(
      :order_with_line_items,
      line_items_attributes: [{variant:, price: 98}]
    )
  }
  let(:context) { Spree::OrderRecalculation::Context.new(order: order) }

  before do
    variant.price = 100
    variant.save!
    order.reload
  end

  it "yields the context to the continuation" do
    expect { |b| described_class.new.call(context, &b) }.to yield_with_args(context)
  end

  it "yields exactly once" do
    expect { |b| described_class.new.call(context, &b) }.to yield_control.once
  end

  context "when Spree::Config.recalculate_cart_prices is true" do
    before { stub_spree_preferences(recalculate_cart_prices: true) }

    it "sets line-item prices to the variant's current price" do
      expect { described_class.new.call(context) { |_ctx| } }
        .to change { order.line_items.first.price }.from(98).to(100)
    end
  end

  context "when Spree::Config.recalculate_cart_prices is false" do
    it "does not change line-item prices" do
      expect { described_class.new.call(context) { |_ctx| } }
        .not_to change { order.line_items.first.price }.from(98)
    end
  end
end
