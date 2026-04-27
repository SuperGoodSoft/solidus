# frozen_string_literal: true

require "rails_helper"

module Spree
  RSpec.describe OrderRecalculator, type: :model do
    let(:updater) { described_class.new(order) }

    include_examples "an order recalculator"
  end

  RSpec.describe Order, "#recalculator opt-in routing", type: :model do
    let!(:store) { create(:store) }
    let(:order) { Spree::Order.create }

    before { allow(Spree::Config).to receive(:order_recalculator_class).and_return(Spree::OrderRecalculator) }

    it "returns a Spree::OrderRecalculator instance" do
      expect(order.recalculator).to be_a(Spree::OrderRecalculator)
    end
  end
end
