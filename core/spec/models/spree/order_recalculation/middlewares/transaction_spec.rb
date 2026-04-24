# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Middlewares::Transaction do
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

  it "wraps the yield in an order.transaction block" do
    open_transactions_inside_yield = nil
    open_transactions_outside =
      ActiveRecord::Base.connection.open_transactions

    described_class.new.call(context) do |_ctx|
      open_transactions_inside_yield =
        ActiveRecord::Base.connection.open_transactions
    end

    expect(open_transactions_inside_yield)
      .to be > open_transactions_outside
  end
end
