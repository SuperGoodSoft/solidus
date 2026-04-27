# frozen_string_literal: true

require "rails_helper"

module Spree
  RSpec.describe InMemoryOrderUpdater, type: :model do
    let(:updater) { described_class.new(order) }

    include_examples "an order recalculator"
  end
end
