# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spree::OrderRecalculation::Context do
  let(:order) { instance_double(Spree::Order) }

  describe "#initialize" do
    it "stores the order" do
      context = described_class.new(order: order)
      expect(context.order).to eq(order)
    end

    it "defaults persist to true" do
      context = described_class.new(order: order)
      expect(context.persist?).to be(true)
    end

    it "accepts persist: false" do
      context = described_class.new(order: order, persist: false)
      expect(context.persist?).to be(false)
    end
  end
end
