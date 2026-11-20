# Cloudflare Migration Plan — GUZA GURA

Status: architecture and migration specification; current repository describes an MVP scaffold. No live marketplace capability or production migration is claimed.

## Target platform
- Next.js App Router on Cloudflare Workers via OpenNext.
- D1 for accounts, profiles, categories, listings, conversations, messages, orders, payment references, moderation and audit events.
- R2 for listing images, with MIME validation, byte/count limits, randomized object keys and ownership checks.
- Cloudflare Turnstile, rate limiting and abuse controls on public write paths.
- Cloudflare Access + MFA for privileged moderator/admin console access only.
- Public buyers, sellers and merchants require application-native identity/session flows; Cloudflare Access is not a public consumer identity system.
- GitHub Actions for migration, test, build and deployment gates.

## Identity and authorization
- Implement verified email/phone challenge and server-managed sessions with secure, HttpOnly, SameSite cookies; select and document the delivery provider before enabling account creation.
- Bind every seller, buyer and merchant operation to the authenticated server-side profile. Never trust role, owner, price, stock or payment status supplied by the browser.
- Keep admin/moderator privileges separate from public signup and require MFA through Access.
- Enforce conversation participant isolation and buyer/seller order ownership in every API query.

## Data migration
- Translate the existing PostgreSQL marketplace schema into ordered D1 SQLite migrations, replacing PostgreSQL-only enums, generated columns, UUID defaults, JSONB and full-text indexes with supported SQLite equivalents.
- Preserve UGX integer minor-unit conventions (UGX has no fractional subunit in this product model), listing moderation states, order state transitions, idempotency keys and append-only audit history.
- R2 objects remain private until authorized listing visibility checks pass.
- No production Supabase export or customer dataset is established by this plan. Do not claim data recovery or import.

## Payment boundary
- Keep checkout disabled until a Uganda-supported payment provider, merchant settlement model, webhook verification, reconciliation, refunds and idempotency have been independently validated.
- Cash-on-collection is not proof of payment. Never store card data or mobile-money PINs. The platform must not custody funds under the current product constitution.

## Acceptance gates
1. Remove Supabase SDKs, Supabase URL/key/service-role settings and Vercel deployment assumptions.
2. D1 migrations apply cleanly and schema constraints/indexes are tested.
3. Anonymous, buyer, seller, merchant and moderator authorization tests pass.
4. Listing moderation, image ownership, message isolation, saved-listing privacy and order isolation tests pass.
5. Atomic inventory reservation and duplicate/invalid payment webhook tests pass before checkout is enabled.
6. Production build, Worker dry-run and mobile browser E2E pass.
7. D1 backup restore, R2 object recovery and production smoke tests pass before cutover.

## Current limitations
The repository explicitly states authentication, database-backed listings, messaging, checkout and payments are not yet implemented. Migration work must not represent these as operational features. Cloudflare account provisioning and production deployment require an authorized Cloudflare control-plane session.
