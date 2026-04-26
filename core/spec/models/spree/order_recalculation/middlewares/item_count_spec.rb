# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::ItemCount do
  let!(:store) { create(:store) }
  let(:order) { create(:order_with_line_items) }
  let(:context) { Spree::OrderRecalculation::Context.new(order: order) }

  before do
    order.line_items.first.quantity = 3
  end

  it "yields the context to the continuation" do
    expect { |b| described_class.new.call(context, &b) }
      .to yield_with_args(context)
  end

  it "yields exactly once" do
    expect { |b| described_class.new.call(context, &b) }
      .to yield_control.once
  end

  it "sets order.item_count to the sum of line-item quantities" do
    expect { described_class.new.call(context) { |_ctx| } }
      .to change { order.item_count }.from(1).to(3)
  end
end
