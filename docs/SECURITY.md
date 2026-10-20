# Security model

Supabase Auth owns identity; profile ID must match auth.uid(). Never grant admin through public signup or client metadata. Test RLS with anonymous, buyer, seller, merchant and admin identities.

Public data: published listing, seller display name and coarse town/area. Private data: contact details, messages, orders, payment references and moderation records. Validate image MIME/size/count, randomize paths, rate-limit listings/messages/reports and moderate prohibited goods.

Compute totals and reserve stock server-side atomically. Never store card data or mobile-money PINs. Verify payment webhook signature, amount, order reference and idempotency. Cash collection is not prepaid settlement. Keep service-role/provider keys server-only. Require admin MFA, least privilege, backups and restore drills.

Before production add admin-only moderation policies, safe public seller view, storage policies, updated_at triggers, trusted order RPC, immutable payment transitions, atomic stock reservation, audit triggers and state-transition validation. Starter is not production security certification.
