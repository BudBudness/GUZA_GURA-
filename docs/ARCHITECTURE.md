# Architecture

Next.js App Router + TypeScript on Vercel; GitHub for source/CI; Supabase Auth, PostgreSQL, Storage and authorized Realtime.

## Data flow
Public catalogue reads only published listings. Seller writes require authenticated identity and RLS. New listings default to pending review. Checkout validates price, stock, delivery and fees server-side. Payment callbacks require signature verification, amount/reference checks and idempotency.

## Routes
/, /search, /category/[slug], /listing/[slug], /sell, /seller, /seller/listings, /saved, /messages, /messages/[id], /cart, /checkout, /orders, /seller/orders, /account, /admin/listings, /admin/reports, /admin/users.

## Environment
NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, server-only SUPABASE_SERVICE_ROLE_KEY. Provider secrets remain server-only.

## Release
Create dedicated Supabase project, review/apply migrations, configure auth/storage policies, connect GitHub to Vercel, set preview/production environment variables, validate preview and run acceptance/security tests before release.
