# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Runner do
  let!(:store) { create(:store) }
  let(:order) { Spree::Order.create }
  let(:context) { Spree::OrderRecalculation::Context.new(order: order) }

  it "invokes each middleware in order with the context" do
    recorder = []

    first = Class.new {
      define_method(:call) do |ctx, &inner|
        recorder << :first
        inner.call(ctx)
      end
    }
    second = Class.new {
      define_method(:call) do |ctx, &inner|
        recorder << :second
        inner.call(ctx)
      end
    }
    stub_const("RunnerMiddlewares::First", first)
    stub_const("RunnerMiddlewares::Second", second)

    list = Spree::Core::ClassConstantizer::List.new
    list.concat(["RunnerMiddlewares::First", "RunnerMiddlewares::Second"])

    described_class.call(list, context)

    expect(recorder).to eq([:first, :second])
  end

  it "is a no-op on an empty list" do
    list = Spree::Core::ClassConstantizer::List.new

    expect { described_class.call(list, context) }.not_to raise_error
  end
end
