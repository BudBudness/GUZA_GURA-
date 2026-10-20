# Acceptance tests

- [ ] npm ci, npm run typecheck, npm run lint and npm run build pass.
- [ ] PWA manifest loads; app installs on supported browsers; mobile 360px has no horizontal overflow.
- [ ] Public visitors only see published listings; search/category/price/location filters compose; empty state resets.
- [ ] Anonymous users cannot create listings/messages or edit another seller's listings.
- [ ] Seller cannot bypass moderation state via client requests; image uploads enforce MIME, size and ownership.
- [ ] Only conversation participants read messages; sender matches authenticated identity.
- [ ] Saved listings are private to the account.
- [ ] Server recalculates order totals and reserves stock atomically; concurrent checkout cannot oversell.
- [ ] Buyer/seller see only their orders; clients cannot mark payment successful.
- [ ] Duplicate webhooks are idempotent; invalid signature and amount mismatch are rejected.
- [ ] Cash on collection is not automatically marked paid; cancellation/refund transitions are tested.
- [ ] No service-role key in client bundles/source/logs; security headers, backup restore and policies verified.
