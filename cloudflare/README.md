# GUZA GURA Cloudflare catalogue slice

This folder contains the first executable Cloudflare Worker + D1 slice.

## Routes

- `GET /health` — Worker health response.
- `GET /api/categories` — active categories only.
- `GET /api/catalogue` — published listings in active categories only.

Catalogue query parameters: `q`, `category` (category slug), `town`, `min_price`, `max_price`, `sort` (`latest`, `price_asc`, `price_desc`), `page`, and `limit` (maximum 50).

The API is read-only. It never accepts seller IDs, status, roles, prices, or listing writes from a client. Search input is reduced to literal FTS5 word tokens and all values are bound parameters. R2 object keys are not exposed; image delivery remains gated on an authenticated/private-object design.

## Local verification

From the repository root:

```sh
python cloudflare/tests/validate_migration.py
```

## Local Worker run

1. Create a D1 database in the Cloudflare account.
2. Copy `cloudflare/wrangler.toml.example` to `cloudflare/wrangler.toml` and replace the database ID with the actual D1 ID.
3. Apply migrations locally with `npx wrangler --config cloudflare/wrangler.toml d1 migrations apply guza-gura --local`.
4. Start the Worker with `npx wrangler --config cloudflare/wrangler.toml dev --local`.

No database ID, Cloudflare credentials, production binding, deployment, or DNS change is included in this repository slice.
