# frozen_string_literal: true

require "rails_helper"
require "solidus_promotions/promotion_migrator"
require "solidus_promotions/promotion_map"

RSpec.describe SolidusPromotions::PromotionMigrator do
  let(:promotion_map) { SolidusPromotions::PROMOTION_MAP }
  let!(:spree_promotion) { create(:promotion, :with_action, :with_item_total_rule, apply_automatically: true) }

  subject(:promotion_migrator) { SolidusPromotions::PromotionMigrator.new(promotion_map).call }

  it "stores original promotion and original promotion action" do
    subject
    expect(SolidusPromotions::Promotion.first.original_promotion).to eq(spree_promotion)
    expect(SolidusPromotions::Benefit.first.original_promotion_action).to eq(spree_promotion.promotion_actions.first)
  end

  context "when an existing promotion has a promotion category" do
    let(:spree_promotion_category) { create(:promotion_category, name: "Sith") }
    let(:spree_promotion) { create(:promotion, promotion_category: spree_promotion_category) }

    it "creates promotion categories that match the old promotion categories" do
      expect { subject }.to change { SolidusPromotions::PromotionCategory.count }.by(1)
      promotion_category = SolidusPromotions::PromotionCategory.first
      expect(promotion_category.name).to eq("Sith")
    end
  end

  context "when an existing promotion has promotion codes" do
    let(:spree_promotion) { create(:promotion, code: "ANDOR LIFE") }

    it "creates codes for the new promotion, identical to the previous one" do
      expect { subject }.to change { SolidusPromotions::PromotionCode.count }.by(1)
      promotion_code = SolidusPromotions::PromotionCode.first
      expect(promotion_code.value).to eq("andor life")
    end
  end

  context "when an existing promotion has promotion codes with promotion code batches" do
    let!(:promotion_code_batch) do
      Spree::PromotionCodeBatch.new(promotion: spree_promotion, base_code: "DISNEY4LIFE", number_of_codes: 1)
    end

    let!(:promotion_code) { create(:promotion_code, promotion: spree_promotion, promotion_code_batch: promotion_code_batch) }
    let(:spree_promotion) { create(:promotion) }

    it "creates the promotion code batch copy" do
      expect { subject }.to change { SolidusPromotions::PromotionCodeBatch.count }.by(1)
      promotion_code_batch = SolidusPromotions::PromotionCodeBatch.first
      expect(promotion_code_batch.base_code).to eq("DISNEY4LIFE")
    end
  end

  context "if our rules and actions are missing from the promotion map" do
    let(:promotion_map) do
      {
        rules: {},
        actions: {}
      }
    end

    it "still creates the promotion, but without rules or actions" do
      subject
      expect(Spree::Promotion.count).not_to be_zero
      expect(SolidusPromotions::Promotion.count).to eq(Spree::Promotion.count)
    end
  end
end
