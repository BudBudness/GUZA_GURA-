# Cloudflare migration — controlled implementation contract

Status: architecture gate; no production resources changed.

## Target runtime

- Cloudflare Workers: application/API runtime, subject to validation of the existing Next.js app-router features and deployment adapter.
- D1: profiles, categories, listings, listing images metadata, saved listings, conversations, messages, orders, order items, payments, reports and audit events.
- R2: listing images and private uploads.
- Turnstile: signup/listing/message/report/checkout abuse controls where appropriate.
- GitHub Actions: deterministic tests, local D1 migrations, preview deployment and release approval.

## Current state and incompatibilities

The application is an early mobile-first Next.js scaffold. The current migration is PostgreSQL-specific and depends on Supabase Auth, `auth.uid()`, PostgreSQL enums, generated columns, extensions, GIN full-text indexes and RLS. The application currently renders demo listings. The existing architecture and security docs describe Supabase/Vercel. No production marketplace workflows are verified.

A direct SQL copy to D1 is unsafe. D1 does not provide Supabase Auth or PostgreSQL RLS. Payment and stock workflows must not be enabled until transactional invariants are implemented and tested.

## Required port

1. Introduce typed repository interfaces for catalogue, identity, messaging, orders, payments and moderation. Keep UI components independent of Supabase SDKs.
2. Port PostgreSQL types to SQLite/D1 deliberately: UUIDs as application-generated TEXT, enums as TEXT with CHECK constraints, timestamps as UTC ISO-8601 TEXT, JSONB as validated JSON TEXT.
3. Replace `auth.uid()` and `auth.users` with a selected identity/session model. Store passwordless/OAuth identity only after explicit provider selection; never trust client-supplied user IDs or roles.
4. Replace each RLS policy with explicit server-side authorization and tenant/participant scoping. Admin privileges must be server-owned and MFA-protected.
5. Use D1 transactions/batches for atomic order creation and stock reservation. Enforce stock availability, seller acceptance and order state transitions server-side.
6. Make payment initiation and webhook handling idempotent. Verify provider signatures, currency, amount, order reference and state transition. Never mark cash-on-collection as paid. Do not custody funds.
7. Store images in R2 using random object keys and metadata in D1. Enforce ownership, MIME, byte limits, count limits and private upload authorization.
8. Add append-only audit events for moderation, order and payment transitions. Restrict reports, messages, orders and payment records to authorized participants/staff.
9. Add abuse controls and prohibited-item moderation before public seller onboarding.
10. Implement numbered forward-only migrations, D1 export, backup retention and a tested restore rehearsal before data migration.

## Data model mapping

| Existing PostgreSQL feature | D1 implementation |
| --- | --- |
| UUID / gen_random_uuid() | application-generated UUID text |
| enum types | TEXT plus CHECK constraints |
| generated total_ugx | compute server-side and persist immutable order totals in transaction |
| timestamptz | ISO-8601 UTC TEXT |
| JSONB | validated JSON TEXT |
| auth.uid() / auth.users | selected identity/session service |
| RLS | explicit Worker authorization, participant checks and admin policy |
| GIN full-text search | SQLite FTS5 virtual table with tested synchronization |
| Supabase Storage | R2 object keys and controlled access |

## Release gates

- [ ] Cloudflare runtime compatibility verified against actual app routes and build output.
- [ ] Identity, session, role and account recovery model implemented; no client role escalation.
- [ ] D1 schema and migration tests pass locally.
- [ ] Public catalogue exposes only published listings and active categories.
- [ ] Seller listing writes enforce ownership and moderation state transitions.
- [ ] Conversation/message tests enforce participant access and sender identity.
- [ ] Order tests prove server-calculated totals, atomic stock reservation and no oversell under concurrency.
- [ ] Payment tests prove signature validation, amount/currency/order matching, idempotency and valid transitions.
- [ ] R2 tests cover authorization, MIME, size, ownership and private access.
- [ ] Moderation, reporting, audit and prohibited-item controls verified.
- [ ] D1 export/restore rehearsal passes with checksums and row counts.
- [ ] Preview end-to-end tests pass.
- [ ] Operator separately approves production data migration and DNS cutover.

## Explicit non-actions

No production DNS, Cloudflare resources, payment credentials, customer data, or legacy Supabase project are changed by this document. No payment processing or live marketplace launch is enabled.
