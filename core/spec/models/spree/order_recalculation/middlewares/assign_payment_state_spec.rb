# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::AssignPaymentState do
  let!(:store) { create(:store) }
  let(:order) { Spree::Order.create }
  let(:context) { Spree::OrderRecalculation::Context.new(order: order) }

  it "yields the context to the continuation" do
    expect { |b| described_class.new.call(context, &b) }.to yield_with_args(context)
  end

  it "yields exactly once" do
    expect { |b| described_class.new.call(context, &b) }.to yield_control.once
  end

  context "when outstanding_balance is zero" do
    before do
      allow(order).to receive(:outstanding_balance).and_return(0)
    end

    it "assigns paid" do
      expect { described_class.new.call(context) { |_ctx| } }
        .to change { order.payment_state }.to("paid")
    end
  end

  context "when outstanding_balance is positive" do
    before do
      allow(order).to receive(:outstanding_balance).and_return(5)
    end

    it "assigns balance_due" do
      expect { described_class.new.call(context) { |_ctx| } }
        .to change { order.payment_state }.to("balance_due")
    end
  end

  context "when outstanding_balance is negative" do
    before do
      allow(order).to receive(:outstanding_balance).and_return(-5)
    end

    it "assigns credit_owed" do
      expect { described_class.new.call(context) { |_ctx| } }
        .to change { order.payment_state }.to("credit_owed")
    end
  end

  context "when the order is canceled and payment_total is zero" do
    before do
      order.state = "canceled"
      order.payment_total = 0
      allow(order).to receive(:outstanding_balance).and_return(0)
    end

    it "assigns void" do
      expect { described_class.new.call(context) { |_ctx| } }
        .to change { order.payment_state }.to("void")
    end
  end

  context "when payments exist but none are valid and there is an outstanding balance" do
    before do
      payments = double("payments")
      allow(payments).to receive(:present?).and_return(true)
      allow(payments).to receive_message_chain(:valid, :empty?).and_return(true)
      allow(order).to receive(:payments).and_return(payments)
      allow(order).to receive(:outstanding_balance).and_return(5)
    end

    it "assigns failed" do
      expect { described_class.new.call(context) { |_ctx| } }
        .to change { order.payment_state }.to("failed")
    end
  end
end
