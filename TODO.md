In-Memory Order Updater TODO
===

- [x] Add additional cases to item_total_updater_spec (doesn't currently account for included adjustments)
- [x] Consider Sofia's recommendation to break this class into POROs to simplify testing
- [x] Add test coverage for `recalculate_item_total` when line item totals change
- [ ] Handle persistence in `update_promotions`
- [ ] Handle persistence in `update_taxes`
- [ ] Write the `InMemoryOrderAdjuster` (also, should we rename this to `InMemoryOrderPromotionAdjuster`)

- [ ] Test coverage to ensure state changes aren't persisted (if someone changes current implementation)
- [ ] Should we blow up if something tries to persist?
