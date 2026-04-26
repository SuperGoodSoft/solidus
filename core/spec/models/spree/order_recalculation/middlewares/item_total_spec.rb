# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::ItemTotal do
  let!(:store) { create(:store) }
  let(:order) {
    create(
      :order_with_line_items,
      line_items_attributes: [
        {price: 10, quantity: 2},
        {price: 7, quantity: 3}
      ]
    )
  }
  let(:context) { Spree::OrderRecalculation::Context.new(order: order) }

  before do
    order.update_columns(item_total: 0)
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

  it "sets order.item_total to the sum of line-item amounts" do
    expect { described_class.new.call(context) { |_ctx| } }
      .to change { order.item_total }.from(0).to(41)
  end
end
