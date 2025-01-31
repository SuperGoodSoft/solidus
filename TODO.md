In-Memory Order Updater TODO
===

- [x] MUST BE NEXT: Rebase this branch against #6080 and clean up the churn. https://github.com/solidusio/solidus/pull/6080

- [x] Add additional cases to item_total_updater_spec (doesn't currently account for included adjustments)
- [x] Consider Sofia's recommendation to break this class into POROs to simplify testing
- [x] Add test coverage for `recalculate_item_total` when line item totals change
- [x] Scope handling of tax adjustments in `InMemoryOrderUpdater` to *not* marked for destruction
- [x] Scope handling of tax adjustments in `OrderUpdater` to *not* marked for destruction
- [x] Ensure order-level tax adjustments (like Colorado delivery) are scoped out of tax total and adjustment total calculations
- [x] Handle persistence in `update_taxes`
- [ ] Handle persistence in `update_promotions`
- [ ] Write the `InMemoryOrderAdjuster` (also, should we rename this to `InMemoryOrderPromotionAdjuster`)

- [ ] Test coverage to ensure state changes aren't persisted (if someone changes current implementation)
- [ ] Should we blow up if something tries to persist?
  - Some thoughts from the initial conservation
   - "By calling this in memory order updater, we are making a contract with the user that it will be in memory"
   - "This is really something which theoritically should be covered in tests"
   - "Our inMemoryOrderUpdater probably shouldnt take a persist true flag"
   - thinking about other changes to solidus deep in the stack
   - thinking about users configuring all the configurable classes

