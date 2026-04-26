# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::PaymentTotal do
  let!(:store) { create(:store) }
  let(:order) { create(:order_with_line_items) }
  let(:context) { Spree::OrderRecalculation::Context.new(order: order) }

  before do
    create(:payment, order: order, state: "completed", amount: 40)
    create(:payment_with_refund, order: order, amount: 100, refund_amount: 5)
    order.update_columns(payment_total: 0)
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

  it "sets order.payment_total to completed payments minus refunds" do
    expect { described_class.new.call(context) { |_ctx| } }
      .to change { order.payment_total }.to(135)
  end
end
